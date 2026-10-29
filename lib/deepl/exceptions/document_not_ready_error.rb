# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    # HTTP 503 on a document download: the translated document is not ready yet. Raised after
    # the retries.
    class DocumentNotReadyError < ServerError
      def to_s
        message = body_message
        message ? "Document not ready: #{message}" : 'Document not ready.'
      end
    end
  end
end
