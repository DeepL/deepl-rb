# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class CreateImport < Base
        attr_reader :file_name, :content_length

        def initialize(api, file_name, content_length, options = {}, additional_headers = {})
          super(api, options, additional_headers)
          @file_name = file_name
          @content_length = content_length
          @content_type = delete_option(:content_type)
          @display_name = delete_option(:display_name)
        end

        def request
          build_translation_memory_import(*execute_request_with_retries(post_request(payload)))
        end

        def details
          "HTTP Headers: #{headers}\nPayload #{payload}"
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        def payload
          source_file = { file_name: file_name, content_length: content_length }
          source_file[:content_type] = @content_type if @content_type
          payload = { source_file: source_file }
          payload[:parameters] = { display_name: @display_name } if @display_name
          payload
        end

        def build_translation_memory_import(request, response)
          data = JSON.parse(response.body)
          Resources::TranslationMemoryImport.new(data, request, response)
        end

        def path
          'translation_memories/import'
        end
      end
    end
  end
end
