# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    ##
    # A network failure without an HTTP response (DNS, connection, TLS or timeout), raised after
    # the retries are used up. The original exception is available as +cause+.
    class ConnectionError < Error
      def should_retry?
        true
      end
    end
  end
end
