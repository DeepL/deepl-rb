# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class Segments < Base
        SUPPORTED_OPTIONS = %w[page_size page_cursor filter_text filter_case_sensitive].freeze

        attr_reader :translation_memory_id

        def initialize(api, translation_memory_id, options = {})
          super(api, options)
          @translation_memory_id = translation_memory_id
        end

        def request
          build_segments(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_segments(request, response)
          data = JSON.parse(response.body)
          Resources::TranslationMemorySegments.new(data, request, response)
        end

        def query_params
          SUPPORTED_OPTIONS.each_with_object({}) do |option_name, params|
            params[option_name] = option(option_name).to_s if option?(option_name)
          end
        end

        def path
          "translation_memories/#{translation_memory_id}/segments"
        end
      end
    end
  end
end
