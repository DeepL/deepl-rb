# Copyright 2021 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class Language < Base
      attr_reader :code, :name

      # +client:+ is true for a language returned by DeepL::Client. @api private
      def initialize(code, name, supports_formality, *args, client: false)
        super(*args)

        @code = code
        @name = name
        @supports_formality = supports_formality
        @client = client
      end

      def to_s
        "#{code} - #{name}"
      end

      # Whether the target language supports the +formality+ option.
      #
      # @return [Boolean, nil] +true+ or +false+ for a target language; for a source language
      #   +nil+ if it came from DeepL::Client.
      # @raise [DeepL::Exceptions::NotSupported] For a source language from the module-level
      #   +DeepL.languages+, until the next major version.
      def supports_formality?
        return @supports_formality unless @supports_formality.nil? && !@client

        raise Exceptions::NotSupported, 'Support formality is only available on target languages'
      end
    end
  end
end
