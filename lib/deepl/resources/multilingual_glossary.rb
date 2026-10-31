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
      # @return [Hash{String => String}] The target term of each source term.
      attr_reader :entries
      attr_reader :source_lang, :target_lang

      ##
      # @param [String] source_lang Source language code, for example +'en'+.
      # @param [String] target_lang Target language code, for example +'de'+.
      # @param [Hash{String => String}, Array<Array(String, String)>, String] entries The target
      #   term of each source term, as a hash, source/target pairs or a TSV string; terms are
      #   stripped and checked when sent.
      # @raise [DeepL::Exceptions::ValidationError] If a pair or TSV line is not exactly two
      #   terms, or a source term appears twice.
      def initialize(source_lang, target_lang, entries, request = nil, response = nil)
        super(request, response)

        @source_lang = source_lang
        @target_lang = target_lang
        pairs = entries.is_a?(String) ? self.class.tsv_to_pairs(entries) : entries.to_a
        @entries = self.class.check_pairs!(pairs).to_h
      end

      # @api private
      # Builds the entries from a dictionary of the API, whose entries are a TSV string.
      def self.from_response(dictionary, request, response)
        entries = (dictionary['entries'] || '').split(/\r?\n/).reject(&:empty?).to_h do |line|
          source, target = line.split("\t", 2)
          [source, target]
        end
        new(dictionary['source_lang'], dictionary['target_lang'], entries, request, response)
      end

      # @api private
      # Raises ValidationError unless each pair is two strings and no source term, stripped as
      # the term check strips it, appears twice. Returns +pairs+.
      def self.check_pairs!(pairs)
        seen = {}
        pairs.each do |pair|
          unless pair.is_a?(Array) && pair.size == 2 && pair.all?(String)
            raise Exceptions::ValidationError, "Entry #{pair.inspect} must be two terms"
          end

          source = pair.first.strip
          next seen[source] = true unless seen[source]

          raise Exceptions::ValidationError, "Duplicate source term #{source.inspect}"
        end
      end

      # @api private
      # One source/target pair per non-blank line, separated by a single tab.
      def self.tsv_to_pairs(tsv)
        tsv.split(/\r?\n/).reject { |line| line.strip.empty? }.map do |line|
          pair = line.split("\t", -1)
          unless pair.size == 2
            raise Exceptions::ValidationError,
                  "TSV entry #{line.inspect} must be a source and a target term separated by " \
                  'one tab'
          end

          pair
        end
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
