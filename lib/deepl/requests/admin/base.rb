# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'date'

module DeepL
  module Requests
    module Admin
      class Base < Requests::Base
        def initialize(api, extra_body_parameters = nil)
          options = {}
          options[:extra_body_parameters] = extra_body_parameters unless extra_body_parameters.nil?
          super(api, options)
        end

        def to_s
          "#{http_method} #{uri.request_uri}"
        end

        private

        def http_method
          'GET'
        end

        def get_request # rubocop:disable Naming/AccessorMethodName
          Net::HTTP::Get.new(uri.request_uri, add_json_content_type(headers))
        end

        def uri
          @uri ||= begin
            base_uri = URI(url)
            query_string = encode_query(query_params)
            base_uri.query = query_string unless query_string.empty?
            base_uri
          end
        end

        def query_params
          {}
        end

        def date_range_params(start_date, end_date)
          start_day = parse_date(start_date)
          end_day = parse_date(end_date)

          { 'start_date' => start_day.iso8601, 'end_date' => end_day.iso8601 }
        end

        def parse_date(value)
          return value.new_offset(0).to_date if value.is_a?(DateTime)
          return value if value.is_a?(Date)
          return value.getutc.to_date if value.is_a?(Time)

          date = parse_date_string(value) if value.is_a?(String)
          return date if date

          raise ArgumentError,
                "Invalid date #{value.inspect}, expected a Date, a Time, a DateTime or " \
                'a YYYY-MM-DD string'
        end

        def parse_date_string(value)
          return nil unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

          year, month, day = value.split('-').map(&:to_i)
          Date.new(year, month, day) if Date.valid_date?(year, month, day)
        end

        def build_developer_key(request, response)
          data = JSON.parse(response.body)
          raise DeepL::Exceptions::Error, 'Developer key response is missing key_id' unless
            usable_developer_key?(data)

          Resources::DeveloperKey.new(data, request, response)
        end

        def usable_developer_key?(data)
          data.is_a?(Hash) && data['key_id'].is_a?(String) && !data['key_id'].empty?
        end

        def parse_json_object(response)
          data = JSON.parse(response.body)
          raise DeepL::Exceptions::Error, 'Analytics response is not a JSON object' unless
            data.is_a?(Hash)

          data
        end
      end
    end
  end
end
