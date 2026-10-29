# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleRule
      class DestroyCustomInstruction < Base
        include Helpers

        def initialize(api, style_id, instruction_id, options = {})
          super(api, options)
          @style_id = style_id
          @instruction_id = instruction_id
        end

        def request
          build_response(*execute_request_with_retries(delete_request))
        end

        def to_s
          "DELETE #{uri.request_uri}"
        end

        private

        def build_response(_, _)
          @instruction_id
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}")
        end

        def path
          style_rule_path(@style_id, 'custom_instructions', @instruction_id)
        end
      end
    end
  end
end
