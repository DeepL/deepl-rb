# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleRule
      # IDs and paths shared by the style rule requests. A style rule list and a custom
      # instruction are given as their ID or as the resource object.
      module Helpers
        private

        def style_rule_id(style_rule)
          return style_rule.style_id if style_rule.is_a?(DeepL::Resources::StyleRule)

          style_rule
        end

        def custom_instruction_id(instruction)
          return instruction.id if instruction.is_a?(DeepL::Resources::CustomInstruction)

          instruction
        end

        # The path of a style rule list, with its ID and the custom instruction ID URL-encoded.
        def style_rule_path(style_id, suffix = nil, instruction_id = nil)
          segments = ["style_rules/#{escape_path_segment(style_id)}", suffix]
          segments << escape_path_segment(instruction_id) unless instruction_id.nil?
          segments.compact.join('/')
        end
      end
    end
  end
end
