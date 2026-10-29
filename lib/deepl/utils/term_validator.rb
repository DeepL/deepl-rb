# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    module TermValidator
      extend self

      # C0 and C1 control characters plus the Unicode line and paragraph separators.
      INVALID_CHARACTERS = /[\u0000-\u001F\u0080-\u009F  ]/.freeze

      ##
      # Strips surrounding whitespace from a single glossary or spoken term, then checks it
      # before it is serialized into a request.
      #
      # @param [String] term The term to check.
      # @return [String] The stripped term, which is what the request sends.
      # @raise [ArgumentError] If the stripped term is empty or contains a control character.
      def validate!(term)
        term = term.to_s.strip
        raise ArgumentError, 'Term must not be empty' if term.empty?
        if INVALID_CHARACTERS.match?(term)
          raise ArgumentError, "Term #{term.inspect} contains an invalid character"
        end

        term
      end
    end
  end
end
