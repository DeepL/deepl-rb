# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class Error < StandardError
      # @return [Integer, nil] HTTP status of the failed response, +nil+ if there was none.
      attr_reader :http_status_code

      # @param [String, nil] message
      # @param [Integer, nil] http_status_code HTTP status of the failed response.
      # @param [Boolean] should_retry Whether repeating the request may succeed.
      def initialize(message = nil, http_status_code: nil, should_retry: false)
        super(message)
        @http_status_code = http_status_code
        @should_retry = should_retry
      end

      def should_retry?
        @should_retry || false
      end
    end
  end
end
