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

    # The entries of one dictionary. Used as input for +create_multilingual_glossary+,
    # +update_multilingual_glossary+, +update_multilingual_glossary_dictionary+ and
    # +replace_multilingual_glossary_dictionary+, and returned by
    # +get_multilingual_glossary_dictionary_entries+.
    class MultilingualGlossaryDictionaryEntries < Base
      attr_reader :source_lang, :target_lang, :entries

      ##
      # @param [String] source_lang Source language code, for example +'en'+.
      # @param [String] target_lang Target language code, for example +'de'+.
      # @param [Array<Array(String, String)>, Hash{String => String}] entries Source/target term
      #   pairs.
      def initialize(source_lang, target_lang, entries, request = nil, response = nil)
        super(request, response)

        @source_lang = source_lang
        @target_lang = target_lang
        @entries = entries.is_a?(Hash) ? entries.to_a : entries
      end

      # @api private
      # Builds the entries from a dictionary of the API, whose entries are a TSV string.
      def self.from_response(dictionary, request, response)
        entries = (dictionary['entries'] || '').split(/\r?\n/).reject(&:empty?).map do |line|
          line.split("\t", 2)
        end
        new(dictionary['source_lang'], dictionary['target_lang'], entries, request, response)
      end
    end

    class MultilingualGlossary < Base
      attr_reader :id, :name, :creation_time, :dictionaries

      def initialize(glossary, *args)
        super(*args)

        @id = glossary['glossary_id']
        @name = glossary['name']
        @creation_time = Utils::TimeParser.parse_optional_utc_time(glossary['creation_time'])
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
