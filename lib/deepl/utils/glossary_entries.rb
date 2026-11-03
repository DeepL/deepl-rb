# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    # TSV encoding of glossary entries, shared by the v2 and v3 glossary requests.
    # @api private
    module GlossaryEntries
      extend self

      # A hash, source/target pairs or a TSV string of them, checked and joined as TSV.
      def to_tsv(entries)
        entries_class = Resources::MultilingualGlossaryDictionaryEntries
        entries = entries.is_a?(String) ? entries_class.tsv_to_pairs(entries) : entries.to_a
        entries_class.check_pairs!(entries).map do |entry|
          source = TermValidator.validate!(entry.first)
          target = TermValidator.validate!(entry.last)
          "#{source}\t#{target}"
        end.join("\n")
      end

      # Source term to target term, one pair per non-empty TSV line.
      def from_tsv(tsv)
        tsv.to_s.split(/\r?\n/).reject(&:empty?).to_h { |line| line.split("\t", 2) }
      end
    end
  end
end
