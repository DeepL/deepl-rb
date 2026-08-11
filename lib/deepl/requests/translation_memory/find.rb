# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class Find < Base
        attr_reader :translation_memory_id

        def initialize(api, translation_memory_id, options = {})
          super(api, options)
          @translation_memory_id = translation_memory_id
        end

        def request
          build_translation_memory(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_translation_memory(request, response)
          data = JSON.parse(response.body)
          Resources::TranslationMemory.new(data, request, response)
        end

        def path
          "translation_memories/#{translation_memory_id}"
        end
      end
    end
  end
end
