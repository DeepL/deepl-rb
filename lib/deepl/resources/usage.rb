# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class Usage < Base
      COUNT_FIELDS = %i[api_key_character_count api_key_character_limit
                        speech_to_text_minutes_count speech_to_text_minutes_limit
                        speech_to_speech_minutes_count speech_to_speech_minutes_limit].freeze
      PRO_FIELDS = (COUNT_FIELDS + %i[products start_time end_time]).freeze

      attr_reader :character_count, :character_limit, *PRO_FIELDS

      ##
      # The keyword arguments hold the fields only present for API Pro users; each one is nil
      # when the response does not contain it.
      #
      # @param [Integer, nil] api_key_character_count Characters used by this API key.
      # @param [Integer, nil] api_key_character_limit Character limit of this API key.
      # @param [Integer, nil] speech_to_text_minutes_count Speech-to-text minutes used.
      # @param [Integer, nil] speech_to_text_minutes_limit Speech-to-text minutes limit.
      # @param [Integer, nil] speech_to_speech_minutes_count Speech-to-speech minutes used.
      # @param [Integer, nil] speech_to_speech_minutes_limit Speech-to-speech minutes limit.
      # @param [Array<UsageProduct>, nil] products Per-product usage.
      # @param [Time, nil] start_time Start of the current billing period.
      # @param [Time, nil] end_time End of the current billing period.

      def initialize(character_count, character_limit, *args, **pro_fields)
        super(*args)

        unknown = pro_fields.keys - PRO_FIELDS
        raise ArgumentError, "unknown keywords: #{unknown.join(', ')}" unless unknown.empty?

        @character_count = character_count
        @character_limit = character_limit
        PRO_FIELDS.each { |field| instance_variable_set("@#{field}", pro_fields[field]) }
      end

      def to_s
        "#{character_count} / #{character_limit}"
      end

      def quota_exceeded?
        character_count >= character_limit
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
