# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class ServerError < RequestError
      # @param [Boolean] should_retry False for a request that is unsafe to repeat once sent.
      def initialize(response, request = nil, should_retry: true)
        super(response, request)
        @should_retry = should_retry
      end

      def to_s
        'An internal server error occured. Try again after waiting a short period.'
      end

      def should_retry?
        @should_retry
      end
    end
  end
end
