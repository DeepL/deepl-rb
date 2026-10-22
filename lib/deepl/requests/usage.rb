# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    class Usage < Base
      def initialize(api, options = {})
        super
      end

      def request
        build_usage(*execute_request_with_retries(get_request))
      end

      def to_s
        "GET #{uri.request_uri}"
      end

      private

      def build_usage(request, response)
        data = JSON.parse(response.body)
        Resources::Usage.new(data['character_count'], data['character_limit'], request, response,
                             **pro_fields(data))
      end

      def pro_fields(data)
        counts = Resources::Usage::COUNT_FIELDS.to_h { |field| [field, data[field.to_s]] }
        counts.merge(
          products: data['products']&.map { |product| Resources::UsageProduct.new(product) },
          start_time: Utils::TimeParser.parse_optional_time(data['start_time']),
          end_time: Utils::TimeParser.parse_optional_time(data['end_time'])
        )
      end

      def path
        'usage'
      end
    end
  end
end
