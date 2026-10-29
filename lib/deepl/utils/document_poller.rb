# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Utils
    # @api private
    # Polls the status of a document translation every 5 seconds.
    module DocumentPoller
      INTERVAL_S = 5

      extend self

      # Polls until the translation is done and returns that status. Raises
      # DeepL::Exceptions::Error with the API's message when the translation fails, and when
      # +timeout_s+ is set and expires. An unknown status keeps polling.
      def wait_until_done(api, handle, timeout_s: nil)
        deadline = timeout_s.nil? ? nil : monotonic_now + timeout_s
        loop do
          status = get_status(api, handle)
          return status if status.successful?

          raise_if_failed(status)

          sleep(interval_until(deadline, timeout_s))
        end
      end

      # Polls until the translation is done or failed and returns that status, or the last status
      # after +max_queries+ + 1 queries if +max_queries+ is set.
      def wait_until_finished(api, handle, max_queries: nil)
        num_queries = 0
        loop do
          sleep(INTERVAL_S) if num_queries.positive?
          num_queries += 1
          status = get_status(api, handle)
          return status if status.finished? || (!max_queries.nil? && num_queries > max_queries)
        end
      end

      private

      def raise_if_failed(status)
        return unless status.error?

        raise Exceptions::Error, "Document translation failed: #{status.error_message}"
      end

      def get_status(api, handle)
        Requests::Document::GetStatus.new(api, handle.document_id, handle.document_key).request
      end

      def interval_until(deadline, timeout_s)
        return INTERVAL_S if deadline.nil?

        remaining = deadline - monotonic_now
        if remaining <= 0
          raise Exceptions::Error, "Document translation did not finish within #{timeout_s} seconds"
        end

        [INTERVAL_S, remaining].min
      end

      def monotonic_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
