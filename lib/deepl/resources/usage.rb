# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class Usage < Base
      ##
      # The amount used and the maximum amount allowed for one usage type.
      class Detail
        attr_reader :count, :limit

        def initialize(count, limit)
          @count = count
          @limit = limit
        end

        def limit_reached?
          count >= limit
        end

        def to_s
          "#{count} of #{limit}"
        end
      end

      DETAIL_TYPES = %i[document team_document api_key_character speech_to_text_minutes
                        speech_to_speech_minutes].freeze
      KEYWORD_FIELDS = (DETAIL_TYPES + %i[products start_time end_time]).freeze

      attr_reader :character, *KEYWORD_FIELDS

      ##
      # Each keyword argument is nil when the response does not contain the field.
      #
      # @param [Detail, nil] document Document usage, for accounts with a document limit.
      # @param [Detail, nil] team_document Document usage of the whole team.
      # @param [Detail, nil] api_key_character Character usage of this API key (API Pro).
      # @param [Detail, nil] speech_to_text_minutes Speech-to-text usage in minutes (API Pro).
      # @param [Detail, nil] speech_to_speech_minutes Speech-to-speech usage in minutes (API Pro).
      # @param [Array<UsageProduct>, nil] products Per-product usage (API Pro).
      # @param [Time, nil] start_time Start of the current billing period (API Pro).
      # @param [Time, nil] end_time End of the current billing period (API Pro).

      def initialize(character_count, character_limit, *args, **fields)
        super(*args)

        unknown = fields.keys - KEYWORD_FIELDS
        raise ArgumentError, "unknown keywords: #{unknown.join(', ')}" unless unknown.empty?

        @character_count = character_count
        @character_limit = character_limit
        @character = Detail.new(character_count, character_limit) unless
          character_count.nil? || character_limit.nil?
        KEYWORD_FIELDS.each { |field| instance_variable_set("@#{field}", fields[field]) }
      end

      ##
      # @deprecated Use +character.count+ instead.
      def character_count
        deprecated(:character_count, 'character.count')
        @character_count
      end

      ##
      # @deprecated Use +character.limit+ instead.
      def character_limit
        deprecated(:character_limit, 'character.limit')
        @character_limit
      end

      def to_s
        "#{@character_count} / #{@character_limit}"
      end

      ##
      # @deprecated Use +character.limit_reached?+ or +any_limit_reached?+ instead.
      def quota_exceeded?
        deprecated(:quota_exceeded?, 'character.limit_reached? or any_limit_reached?')
        @character_count >= @character_limit
      end

      ##
      # True if the character, document or team document limit has been reached. The API Pro
      # usage types (api_key_character and the speech minutes) are not considered; call
      # limit_reached? on them directly.
      def any_limit_reached?
        [character, document, team_document].compact.any?(&:limit_reached?)
      end

      private

      def deprecated(name, replacement)
        Deprecation.warn_once("DeepL::Resources::Usage##{name}",
                              "[DEPRECATION] DeepL::Resources::Usage##{name} is deprecated, " \
                              "use #{replacement} instead.", uplevel: 3)
      end
    end

    class UsageProduct
      attr_reader :product_type, :billing_unit, :api_key_unit_count, :account_unit_count

      def initialize(product)
        @product_type = product['product_type']
        @billing_unit = product['billing_unit']
        @api_key_unit_count = product['api_key_unit_count']
        @account_unit_count = product['account_unit_count']
      end

      def to_s
        "#{product_type}: #{api_key_unit_count} / #{account_unit_count} #{billing_unit}"
      end
    end
  end
end
