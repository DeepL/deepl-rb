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
          id = style_rule.is_a?(DeepL::Resources::StyleRule) ? style_rule.style_id : style_rule
          raise ArgumentError, 'Style rule ID must not be empty' if id.to_s.empty?

          id
        end

        def custom_instruction_id(instruction)
          id = instruction.is_a?(DeepL::Resources::CustomInstruction) ? instruction.id : instruction
          raise ArgumentError, 'Custom instruction ID must not be empty' if id.to_s.empty?

          id
        end

        # Raises ArgumentError for each of +values+ (name => value) that is nil or empty.
        def check_non_empty!(values)
          values.each do |name, value|
            raise ArgumentError, "`#{name}` must not be empty" if value.to_s.empty?
          end
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
