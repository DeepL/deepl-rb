# Copyright 2025 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'time'

module DeepL
  module Resources
    class CustomInstruction
      attr_reader :id, :label, :prompt, :source_language

      def initialize(custom_instruction_data)
        @id = custom_instruction_data['id']
        @label = custom_instruction_data['label']
        @prompt = custom_instruction_data['prompt']
        @source_language = custom_instruction_data['source_language']
      end
    end

    class StyleRule < Base
      attr_reader :style_id, :name, :creation_time, :updated_time, :language, :version,
                  :configured_rules, :custom_instructions

      def initialize(style_rule, *args)
        super(*args)
        extract_basic_fields(style_rule)
        extract_configured_rules(style_rule)
        extract_custom_instructions(style_rule)
      end

      private

      def extract_basic_fields(style_rule)
        @style_id = style_rule['style_id']
        @name = style_rule['name']
        @creation_time = parse_time(style_rule['creation_time'])
        @updated_time = parse_time(style_rule['updated_time'])
        @language = style_rule['language']
        @version = style_rule['version']
      end

      def extract_configured_rules(style_rule)
        @configured_rules = style_rule['configured_rules']
      end

      def extract_custom_instructions(style_rule)
        @custom_instructions = style_rule['custom_instructions']&.map do |ci|
          CustomInstruction.new(ci)
        end
      end

      def to_s
        "#{style_id} - #{name}"
      end

      def parse_time(time_string)
        return nil unless time_string

        Time.parse(time_string)
      rescue ArgumentError, TypeError
        raise Exceptions::Error,
              "Unexpected response from the DeepL API: invalid time #{time_string.inspect}"
      end
    end
  end
end
