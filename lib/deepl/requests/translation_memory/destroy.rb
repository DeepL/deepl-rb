# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class Destroy < Base
        attr_reader :translation_memory_id

        def initialize(api, translation_memory_id, options = {})
          super(api, options)
          @translation_memory_id = translation_memory_id
        end

        def request
          build_response(*execute_request_with_retries(delete_request))
        end

        def to_s
          "DELETE #{uri.request_uri}"
        end

        private

        def build_response(_, _)
          translation_memory_id
        end

        def path
          "translation_memories/#{translation_memory_id}"
        end
      end
    end
  end
end
