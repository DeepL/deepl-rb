# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class TranslationMemory < Base
      attr_reader :translation_memory_id, :name, :source_language, :target_languages,
                  :segment_count, :creation_time, :updated_time

      def initialize(translation_memory, *args)
        super(*args)
        @translation_memory_id = translation_memory['translation_memory_id']
        @name = translation_memory['name']
        @source_language = translation_memory['source_language']
        @target_languages = translation_memory['target_languages'] || []
        @segment_count = translation_memory['segment_count'] || 0
        @creation_time = Utils::TimeParser.parse_optional_time(translation_memory['creation_time'])
        @updated_time = Utils::TimeParser.parse_optional_time(translation_memory['updated_time'])
      end

      def to_s
        "#{translation_memory_id} - #{name}"
      end
    end
  end
end
