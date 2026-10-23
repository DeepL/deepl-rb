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
                             **usage_fields(data))
      end

      def usage_fields(data)
        details = Resources::Usage::DETAIL_TYPES.to_h { |type| [type, detail(data, type)] }
        details.merge(products: products(data['products']),
                      start_time: optional_time(data['start_time']),
                      end_time: optional_time(data['end_time']))
      end

      def detail(data, type)
        count = data["#{type}_count"]
        limit = data["#{type}_limit"]
        Resources::Usage::Detail.new(count, limit) unless count.nil? || limit.nil?
      end

      def products(entries)
        return nil unless entries.is_a?(Array)

        entries.grep(Hash).map { |product| Resources::UsageProduct.new(product) }
      end

      # An unexpected billing-period format must not fail the whole usage response.
      def optional_time(value)
        Utils::TimeParser.parse_optional_time(value) if value.is_a?(String)
      rescue ArgumentError
        nil
      end

      def path
        'usage'
      end
    end
  end
end
