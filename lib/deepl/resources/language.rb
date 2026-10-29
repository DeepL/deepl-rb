# Copyright 2021 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class Language < Base
      attr_reader :code, :name

      def initialize(code, name, supports_formality, *args)
        super(*args)

        @code = code
        @name = name
        @supports_formality = supports_formality
      end

      def to_s
        "#{code} - #{name}"
      end

      # Whether the target language supports the +formality+ option.
      #
      # @return [Boolean, nil] +true+ or +false+ for a target language, +nil+ for a source
      #   language.
      def supports_formality?
        @supports_formality
      end
    end
  end
end
