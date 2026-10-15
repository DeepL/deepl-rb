# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Requests
    class LanguageResources < Base
      def initialize(api, options = {})
        super
      end

      def request
        build_language_resource_list(*execute_request_with_retries(get_request))
      end

      def to_s
        "GET #{uri.request_uri}"
      end

      private

      def build_language_resource_list(request, response)
        data = JSON.parse(response.body)
        data.map { |resource| Resources::LanguageResource.new(resource, request, response) }
      end

      def uri
        @uri ||= URI("#{host}/v3/#{path}")
      end

      def get_request # rubocop:disable Naming/AccessorMethodName
        Net::HTTP::Get.new(uri.request_uri, add_json_content_type(headers))
      end

      def path
        'languages/resources'
      end
    end
  end
end
