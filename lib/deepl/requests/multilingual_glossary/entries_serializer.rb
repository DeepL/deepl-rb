# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      # Shared helper for serializing dictionary entries to the TSV payload
      # format expected by the v3 multilingual glossary API. Centralizing the
      # serialization keeps the behavior of `Create`, `ReplaceDictionary` and
      # `UpdateDictionary` in sync.
      module EntriesSerializer
        private

        def entries_to_string(entries)
          return entries if entries.is_a?(String)

          entries.map do |entry|
            source = Utils::TermValidator.validate!(entry.first)
            target = Utils::TermValidator.validate!(entry.last)
            "#{source}\t#{target}"
          end.join("\n")
        end
      end
    end
  end
end
