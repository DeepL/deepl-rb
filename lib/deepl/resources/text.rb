# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class Text < Base
      # @return [Integer, nil] Number of characters billed for the text, +nil+ if the response
      #   does not contain it.
      attr_reader :billed_characters
      # @return [String, nil] Tag handling algorithm version used (see
      #   +DeepL::Constants::TagHandlingVersion+), +nil+ if the response does not contain it.
      attr_reader :tag_handling_version
      attr_reader :text, :detected_source_language, :model_type_used

      # Positional, not keyword, parameters: Ruby 2.7 would read the response (it has +to_hash+)
      # as keywords.
      def initialize(text, detected_source_language, model_type_used, request = nil, # rubocop:disable Metrics/ParameterLists
                     response = nil, billed_characters = nil, tag_handling_version = nil)
        super(request, response)

        @text = text
        @detected_source_language = detected_source_language
        @model_type_used = model_type_used
        @billed_characters = billed_characters
        @tag_handling_version = tag_handling_version
      end

      def to_s
        text
      end
    end
  end
end
