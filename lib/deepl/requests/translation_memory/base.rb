# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      ##
      # Common behaviour of the translation memory endpoints: they are served under the `v3`
      # prefix instead of the configured API version, and take their parameters in the query
      # string rather than in the request body.

      class Base < DeepL::Requests::Base
        private

        def uri
          @uri ||= begin
            base_uri = URI("#{host}/v3/#{path}")
            query_string = build_query_string
            base_uri.query = query_string unless query_string.empty?
            base_uri
          end
        end

        def build_query_string
          encode_query(query_params)
        end

        def query_params
          {}
        end

        def get_request # rubocop:disable Naming/AccessorMethodName
          Net::HTTP::Get.new(uri.request_uri, add_json_content_type(headers))
        end

        def delete_request
          Net::HTTP::Delete.new(uri.request_uri, add_json_content_type(headers))
        end
      end
    end
  end
end
