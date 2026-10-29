# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleRule
      class CreateCustomInstruction < Base
        include Helpers

        def initialize(api, style_id, label, prompt, source_language = nil, options = {})
          super(api, options)
          @style_id = style_id
          @label = label
          @prompt = prompt
          @source_language = source_language
        end

        def request
          payload = { label: @label, prompt: @prompt }
          payload[:source_language] = @source_language if @source_language
          build_custom_instruction(*execute_request_with_retries(post_request(payload)))
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        def build_custom_instruction(_request, response)
          data = JSON.parse(response.body)
          DeepL::Resources::CustomInstruction.new(data)
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}")
        end

        def path
          style_rule_path(@style_id, 'custom_instructions')
        end
      end
    end
  end
end
