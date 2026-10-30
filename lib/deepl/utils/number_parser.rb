# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    ##
    # Reads numbers from API responses without failing on unexpected values.
    module NumberParser
      extend self

      # @return [Integer] The value if it is an Integer, otherwise 0.
      def count(value)
        value.is_a?(Integer) ? value : 0
      end

      # @return [Float] The value as a Float if it is numeric, otherwise 0.0.
      def minutes(value)
        value.is_a?(Numeric) ? value.to_f : 0.0
      end

      # @return [Float, nil] The value as a Float if it is numeric, otherwise nil.
      def optional_minutes(value)
        value.is_a?(Numeric) ? value.to_f : nil
      end

      # @return [Integer, nil] The value if it is an Integer, otherwise nil.
      def optional_count(value)
        value.is_a?(Integer) ? value : nil
      end
    end
  end
end
