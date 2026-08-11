# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'time'

module DeepL
  module Utils
    module TimeParser
      extend self

      ##
      # Parses an optional timestamp returned by the API.
      #
      # @param [String, nil] time_string Timestamp in ISO 8601 format, or nil.
      # @return [Time, nil] The parsed time, or nil if no timestamp was given.

      def parse_optional_time(time_string)
        return nil if time_string.nil? || time_string.empty?

        Time.parse(time_string)
      end
    end
  end
end
