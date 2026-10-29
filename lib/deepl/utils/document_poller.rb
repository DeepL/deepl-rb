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

      def get_status(api, handle)
        Requests::Document::GetStatus.new(api, handle.document_id, handle.document_key).request
      end
    end
  end
end
