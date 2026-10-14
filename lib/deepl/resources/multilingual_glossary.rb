# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class MultilingualGlossaryDictionary < Base
      attr_reader :source_lang, :target_lang, :entry_count

      def initialize(dictionary, *args)
        super(*args)

        @source_lang = dictionary['source_lang']
        @target_lang = dictionary['target_lang']
        @entry_count = dictionary['entry_count']
      end

      def to_s
        "#{source_lang} -> #{target_lang} (#{entry_count})"
      end
    end

    class MultilingualGlossaryDictionaryEntries < Base
      attr_reader :source_lang, :target_lang, :entries, :entries_format

      def initialize(dictionary, *args)
        super(*args)

        @source_lang = dictionary['source_lang']
        @target_lang = dictionary['target_lang']
        @entries = dictionary['entries']
        @entries_format = dictionary['entries_format']
      end
    end

    class MultilingualGlossary < Base
      attr_reader :id, :name, :creation_time, :dictionaries

      def initialize(glossary, *args)
        super(*args)

        @id = glossary['glossary_id']
        @name = glossary['name']
        @creation_time = glossary['creation_time']
        @dictionaries = (glossary['dictionaries'] || []).map do |dictionary|
          MultilingualGlossaryDictionary.new(dictionary, *args)
        end
      end

      def to_s
        "#{id} - #{name}"
      end
    end
  end
end
