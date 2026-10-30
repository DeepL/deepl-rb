# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    ##
    # Usage breakdown of an admin usage report. +speech_to_speech_minutes+ is +nil+ when the
    # response does not contain it.
    class AdminUsageBreakdown
      attr_reader :total_characters, :text_translation_characters,
                  :document_translation_characters, :text_improvement_characters,
                  :speech_to_text_minutes, :speech_to_speech_minutes

      def initialize(usage)
        usage = {} unless usage.is_a?(Hash)
        @total_characters = Utils::NumberParser.count(usage['total_characters'])
        @text_translation_characters = Utils::NumberParser.count(usage['text_translation_characters'])
        @document_translation_characters =
          Utils::NumberParser.count(usage['document_translation_characters'])
        @text_improvement_characters = Utils::NumberParser.count(usage['text_improvement_characters'])
        @speech_to_text_minutes = Utils::NumberParser.minutes(usage['speech_to_text_minutes'])
        @speech_to_speech_minutes =
          Utils::NumberParser.optional_minutes(usage['speech_to_speech_minutes'])
      end
    end

    ##
    # Usage of a single API key. +usage_date+ is only set when grouped by key and day;
    # +api_key_label+ is +nil+ when the response does not contain it.
    class KeyUsage
      attr_reader :api_key, :api_key_label, :usage, :usage_date

      def initialize(key_usage)
        @api_key = key_usage['api_key'].is_a?(String) ? key_usage['api_key'] : ''
        @api_key_label = key_usage['api_key_label'].is_a?(String) ? key_usage['api_key_label'] : nil
        @usage = AdminUsageBreakdown.new(key_usage['usage'])
        @usage_date = Utils::TimeParser.parse_optional_utc_time(key_usage['usage_date'])
      end
    end

    ##
    # Admin usage analytics report. +key_usages+ is only filled when grouped by key and
    # +key_and_day_usages+ only when grouped by key and day; otherwise they are empty.
    # +total_usage+, +start_date+ and +end_date+ are +nil+ when the response does not contain them.
    class AdminUsageReport < Base
      attr_reader :total_usage, :start_date, :end_date, :group_by, :key_usages,
                  :key_and_day_usages

      def initialize(data, *args) # rubocop:disable Metrics/AbcSize
        super(*args)
        report = data.is_a?(Hash) ? data['usage_report'] : nil
        report = {} unless report.is_a?(Hash)
        total_usage = report['total_usage']
        @total_usage = total_usage.is_a?(Hash) ? AdminUsageBreakdown.new(total_usage) : nil
        @start_date = Utils::TimeParser.parse_optional_utc_time(report['start_date'])
        @end_date = Utils::TimeParser.parse_optional_utc_time(report['end_date'])
        @group_by = report['group_by'].is_a?(String) ? report['group_by'] : nil
        @key_usages = parse_key_usages(report['key_usages'])
        @key_and_day_usages = parse_key_usages(report['key_and_day_usages'])
      end

      private

      def parse_key_usages(key_usages)
        return [] unless key_usages.is_a?(Array)

        key_usages.grep(Hash).map { |usage| KeyUsage.new(usage) }
      end
    end
  end
end
