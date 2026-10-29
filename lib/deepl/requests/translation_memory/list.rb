# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class List < Base
        SUPPORTED_OPTIONS = %w[page page_size].freeze

        def initialize(api, options = {})
          super
        end

        def request
          build_translation_memory_list(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_translation_memory_list(request, response)
          data = JSON.parse(response.body)
          data['translation_memories'].map do |tm|
            Resources::TranslationMemory.new(tm, request, response)
          end
        end

        def query_params
          SUPPORTED_OPTIONS.each_with_object({}) do |option_name, params|
            value = option(option_name)
            params[option_name] = value.to_s unless value.nil?
          end
        end

        def path
          'translation_memories'
        end
      end
    end
  end
end
