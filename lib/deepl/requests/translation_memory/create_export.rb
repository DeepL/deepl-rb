# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class CreateExport < Base
        attr_reader :translation_memory_id

        def initialize(api, translation_memory_id, options = {})
          super(api, options)
          @translation_memory_id = translation_memory_id
        end

        def request
          build_translation_memory_export(*execute_request_with_retries(post_request({})))
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        def build_translation_memory_export(request, response)
          data = JSON.parse(response.body)
          # The API answers 200 when it reused a previously completed export, and 202 when it
          # started a new one.
          reused_existing = response.code.to_i == 200
          Resources::TranslationMemoryExport.new(data, reused_existing, request, response)
        end

        def path
          "translation_memories/#{translation_memory_id}/export"
        end
      end
    end
  end
end
