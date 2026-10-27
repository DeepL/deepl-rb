# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class CustomTagUsageBreakdown
      attr_reader :total_characters, :text_translation_characters,
                  :text_improvement_characters, :speech_to_text_minutes,
                  :speech_to_speech_minutes

      def initialize(breakdown)
        breakdown = {} unless breakdown.is_a?(Hash)
        @total_characters = Utils::NumberParser.count(breakdown['total_characters'])
        @text_translation_characters =
          Utils::NumberParser.count(breakdown['text_translation_characters'])
        @text_improvement_characters =
          Utils::NumberParser.count(breakdown['text_improvement_characters'])
        @speech_to_text_minutes = Utils::NumberParser.minutes(breakdown['speech_to_text_minutes'])
        @speech_to_speech_minutes =
          Utils::NumberParser.minutes(breakdown['speech_to_speech_minutes'])
      end
    end

    ##
    # Usage of a single custom tag. +usage_date+ is only set when aggregated by day.
    class CustomTagUsage
      attr_reader :custom_tag, :breakdown, :usage_date

      def initialize(usage)
        @custom_tag = usage['custom_tag'].is_a?(String) ? usage['custom_tag'] : ''
        @breakdown = CustomTagUsageBreakdown.new(usage['breakdown'])
        @usage_date = Utils::TimeParser.parse_optional_utc_time(usage['usage_date'])
      end
    end

    ##
    # Custom tag usage analytics report. +next_page+ is +nil+ on the last page.
    class CustomTagUsageReport < Base
      attr_reader :aggregate_by, :start_date, :end_date, :next_page, :usage

      def initialize(data, *args) # rubocop:disable Metrics/AbcSize
        super(*args)
        report = data.is_a?(Hash) ? data['custom_tag_usage_report'] : nil
        report = {} unless report.is_a?(Hash)
        @aggregate_by = report['aggregate_by'].is_a?(String) ? report['aggregate_by'] : nil
        @start_date = Utils::TimeParser.parse_optional_utc_time(report['start_date'])
        @end_date = Utils::TimeParser.parse_optional_utc_time(report['end_date'])
        @next_page = report['next_page'].is_a?(Integer) ? report['next_page'] : nil
        usages = report['usage'].is_a?(Array) ? report['usage'] : []
        @usage = usages.grep(Hash).map { |item| CustomTagUsage.new(item) }
      end
    end
  end
end
