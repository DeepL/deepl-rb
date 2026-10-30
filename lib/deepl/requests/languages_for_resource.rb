# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Requests
    class LanguagesForResource < Base
      def initialize(api, resource, options = {})
        super(api, options)
        @resource = resource.to_s
        raise ArgumentError, 'resource must not be empty' if @resource.empty?
      end

      def request
        build_language_support_list(*execute_request_with_retries(get_request))
      end

      def to_s
        "GET #{uri.request_uri}"
      end

      private

      def build_language_support_list(request, response)
        data = JSON.parse(response.body)
        data.map { |language| Resources::LanguageSupport.new(language, request, response) }
      end

      def uri
        @uri ||= begin
          base_uri = URI("#{host}/v3/#{path}")
          base_uri.query = build_query_string
          base_uri
        end
      end

      # include is sent as repeated include=<value> parameters
      def build_query_string
        params = [['resource', @resource]]
        Array(option(:include)).each { |value| params << ['include', value.to_s] }
        encode_query(params)
      end

      def get_request # rubocop:disable Naming/AccessorMethodName
        Net::HTTP::Get.new(uri.request_uri, add_json_content_type(headers))
      end

      def path
        'languages'
      end
    end
  end
end
