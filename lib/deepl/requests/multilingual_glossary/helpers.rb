# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      # Encoding shared by the v3 glossary requests.
      module Helpers
        private

        def glossary_id(glossary)
          return glossary.id if glossary.is_a?(DeepL::Resources::MultilingualGlossary)

          glossary.to_s
        end

        # The path of a glossary, with its ID URL-encoded.
        def glossary_path(id, suffix = nil)
          ["glossaries/#{escape_path_segment(id)}", suffix].compact.join('/')
        end

        # Accepts a MultilingualGlossaryDictionaryEntries object or a hash with +:source_lang+,
        # +:target_lang+, +:entries+ and optionally +:entries_format+ (default +tsv+).
        def dictionary_payload(dictionary)
          if dictionary.is_a?(DeepL::Resources::MultilingualGlossaryDictionaryEntries)
            return { source_lang: dictionary.source_lang, target_lang: dictionary.target_lang,
                     entries: entries_to_string(dictionary.entries), entries_format: 'tsv' }
          end

          value = ->(key) { dictionary[key] || dictionary[key.to_s] }
          format = value.call(:entries_format) || 'tsv'
          entries = value.call(:entries)
          # CSV content is sent as given; TSV content is parsed so its terms are checked too.
          entries = entries_to_string(entries) unless format == 'csv' && entries.is_a?(String)
          { source_lang: value.call(:source_lang), target_lang: value.call(:target_lang),
            entries: entries, entries_format: format }
        end

        # Source/target pairs, or a TSV string of them, are checked and joined as TSV.
        def entries_to_string(entries)
          entries = tsv_to_pairs(entries) if entries.is_a?(String)
          entries.map do |entry|
            source = Utils::TermValidator.validate!(entry.first)
            target = Utils::TermValidator.validate!(entry.last)
            "#{source}\t#{target}"
          end.join("\n")
        end

        # One source/target pair per non-blank line, separated by a single tab.
        def tsv_to_pairs(tsv)
          tsv.split(/\r?\n/).reject { |line| line.strip.empty? }.map do |line|
            pair = line.split("\t", -1)
            unless pair.size == 2
              raise ArgumentError, "TSV entry #{line.inspect} must be a source and a target term " \
                                   'separated by one tab'
            end

            pair
          end
        end

        def build_glossary(request, response)
          Resources::MultilingualGlossary.new(JSON.parse(response.body), request, response)
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}")
        end
      end
    end
  end
end
