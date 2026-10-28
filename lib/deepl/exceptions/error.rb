# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class Error < StandardError
      # @return [Integer, nil] HTTP status of the failed response, +nil+ if there was none.
      attr_reader :http_status_code

      def should_retry?
        false
      end
    end
  end
end
