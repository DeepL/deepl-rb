# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    # A style profile: a named set of glossaries, style rule lists and translation memories.
    class StyleProfile < Base
      attr_reader :style_profile_id, :name, :description, :industry, :glossary_ids, :style_rule_ids,
                  :translation_memory_ids, :glossary_priority_order_enabled, :creation_time,
                  :updated_time

      def initialize(profile, *args) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        super(*args)

        @style_profile_id = profile['style_profile_id']
        @name = profile['name']
        @description = optional_string(profile['description'])
        @industry = optional_string(profile['industry'])
        @glossary_ids = id_list(profile['glossary_ids'])
        @style_rule_ids = id_list(profile['style_rule_ids'])
        @translation_memory_ids = id_list(profile['translation_memory_ids'])
        @glossary_priority_order_enabled = profile['glossary_priority_order_enabled'] == true
        @creation_time = Utils::TimeParser.parse_optional_utc_time(profile['creation_time'])
        @updated_time = Utils::TimeParser.parse_optional_utc_time(profile['updated_time'])
      end

      def to_s
        "#{style_profile_id} - #{name}"
      end

      private

      def optional_string(value)
        value if value.is_a?(String)
      end

      def id_list(value)
        value.is_a?(Array) ? value.grep(String) : []
      end
    end
  end
end
