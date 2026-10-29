# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    ##
    # Usage limits of a developer key. A +nil+ limit means unlimited.
    class DeveloperKeyUsageLimits
      attr_reader :characters, :speech_to_text_milliseconds, :speech_to_speech_milliseconds

      def initialize(usage_limits)
        usage_limits = {} unless usage_limits.is_a?(Hash)
        @characters = Utils::NumberParser.optional_count(usage_limits['characters'])
        @speech_to_text_milliseconds =
          Utils::NumberParser.optional_count(usage_limits['speech_to_text_milliseconds'])
        @speech_to_speech_milliseconds =
          Utils::NumberParser.optional_count(usage_limits['speech_to_speech_milliseconds'])
      end
    end

    ##
    # A developer key. +label+ and +usage_limits+ are +nil+ when the response does not contain
    # them.
    class DeveloperKey < Base
      attr_reader :key_id, :label, :creation_time, :deactivated_time, :is_deactivated,
                  :usage_limits

      def initialize(developer_key, *args)
        super(*args)
        developer_key = {} unless developer_key.is_a?(Hash)
        @key_id = developer_key['key_id'].is_a?(String) ? developer_key['key_id'] : ''
        @label = developer_key['label'].is_a?(String) ? developer_key['label'] : nil
        @creation_time = Utils::TimeParser.parse_optional_utc_time(developer_key['creation_time'])
        @deactivated_time =
          Utils::TimeParser.parse_optional_utc_time(developer_key['deactivated_time'])
        @is_deactivated = developer_key['is_deactivated'] == true
        @usage_limits = parse_usage_limits(developer_key['usage_limits'])
      end

      def deactivated?
        is_deactivated
      end

      def to_s
        label.nil? ? key_id : "#{label} (#{key_id})"
      end

      private

      def parse_usage_limits(usage_limits)
        usage_limits.is_a?(Hash) ? DeveloperKeyUsageLimits.new(usage_limits) : nil
      end
    end
  end
end
