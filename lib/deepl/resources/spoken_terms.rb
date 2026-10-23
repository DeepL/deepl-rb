# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    # The term count of one language in a spoken terms collection.
    class SpokenTermsList < Base
      attr_reader :lang, :entry_count

      def initialize(term_list, *args)
        super(*args)

        @lang = term_list['lang']
        @entry_count = term_list['entry_count']
      end

      def to_s
        "#{lang} (#{entry_count})"
      end
    end

    # The terms of one language. Used as input for +create+, +update+ and +replace_term_list+,
    # and returned by +entries+.
    class SpokenTermsEntries < Base
      attr_reader :lang, :entries

      ##
      # @param [String] lang Language code, for example +'en'+.
      # @param [Array<String>] entries The terms, one per element.
      def initialize(lang, entries, request = nil, response = nil)
        super(request, response)

        @lang = lang
        @entries = entries
      end
    end

    # A spoken terms collection.
    class SpokenTerms < Base
      attr_reader :id, :name, :creation_time, :term_lists

      def initialize(spoken_terms, *args)
        super(*args)

        @id = spoken_terms['spoken_terms_id']
        @name = spoken_terms['name']
        @creation_time = Utils::TimeParser.parse_optional_time(spoken_terms['creation_time'])
        @term_lists = (spoken_terms['term_lists'] || []).map do |term_list|
          SpokenTermsList.new(term_list, *args)
        end
      end

      def to_s
        "#{id} - #{name}"
      end
    end
  end
end
