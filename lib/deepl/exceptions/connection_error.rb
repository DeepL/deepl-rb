# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    ##
    # A network failure without an HTTP response from the API (DNS, connection, TLS, proxy or
    # timeout), raised after the retries are used up. Transient failures (DNS, connection,
    # timeout) are retried and have +should_retry?+ true; TLS failures, proxy failures and
    # malformed responses are raised at once and have +should_retry?+ false. The original
    # exception is available as +cause+.
    class ConnectionError < Error
      # Raised from a +rescue+ block, so the original exception becomes +cause+.
      def self.from_network_error(error)
        new("Connection to the DeepL API failed: #{error.message}",
            should_retry: transient?(error))
      end

      def self.transient?(error)
        Requests::Base::RETRYABLE_NETWORK_ERRORS.any? { |type| error.is_a?(type) }
      end

      def initialize(message = nil, should_retry: true)
        super(message)
        @should_retry = should_retry
      end

      def should_retry?
        @should_retry
      end
    end
  end
end
