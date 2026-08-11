# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    class TranslationMemoryTargetSegment
      attr_reader :target_segment_id, :target_language, :target_text, :creation_time,
                  :updated_time, :last_used_time

      def initialize(target_segment)
        @target_segment_id = target_segment['target_segment_id']
        @target_language = target_segment['target_language']
        @target_text = target_segment['target_text']
        @creation_time = Utils::TimeParser.parse_optional_time(target_segment['creation_time'])
        @updated_time = Utils::TimeParser.parse_optional_time(target_segment['updated_time'])
        @last_used_time = Utils::TimeParser.parse_optional_time(target_segment['last_used_time'])
      end

      def to_s
        "#{target_language}: #{target_text}"
      end
    end

    class TranslationMemorySegment
      attr_reader :source_segment_id, :source_text, :targets, :creation_time, :updated_time,
                  :last_used_time

      def initialize(segment)
        @source_segment_id = segment['source_segment_id']
        @source_text = segment['source_text']
        @targets = (segment['targets'] || []).map do |target|
          TranslationMemoryTargetSegment.new(target)
        end
        @creation_time = Utils::TimeParser.parse_optional_time(segment['creation_time'])
        @updated_time = Utils::TimeParser.parse_optional_time(segment['updated_time'])
        @last_used_time = Utils::TimeParser.parse_optional_time(segment['last_used_time'])
      end

      def to_s
        "#{source_segment_id} - #{source_text}"
      end
    end

    ##
    # One page of the segments of a translation memory. Pagination is cursor-based: pass
    # `next_page_cursor` as the `page_cursor` option of the next request until it is nil.

    class TranslationMemorySegments < Base
      attr_reader :segments, :segment_count, :next_page_cursor

      def initialize(segments_response, *args)
        super(*args)
        @segments = (segments_response['segments'] || []).map do |segment|
          TranslationMemorySegment.new(segment)
        end
        # Note that this is the number of segments stored in the translation memory, it is not
        # reduced by a text filter.
        @segment_count = segments_response['segment_count'] || 0
        @next_page_cursor = segments_response['next_page_cursor']
      end

      ##
      # Checks whether another page of segments can be requested.
      #
      # @return [true] if so

      def next_page?
        !next_page_cursor.nil?
      end

      def to_s
        "#{segments.size} of #{segment_count} segment(s)"
      end
    end
  end
end
