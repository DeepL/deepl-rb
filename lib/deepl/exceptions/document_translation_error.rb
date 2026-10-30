# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class DocumentTranslationError < Error
      # @return [DeepL::Resources::DocumentHandle, nil] Handle of the uploaded document, +nil+ if
      #   the upload failed. Use it to query the status or download the document later.
      attr_reader :document_handle

      # +error+ is the failure being wrapped; the HTTP status and retryability of a DeepL error
      # are copied from it.
      def initialize(message, handle, error = nil)
        super(message)
        @handle = handle
        @document_handle = handle
        return unless error.is_a?(Error)

        @http_status_code = error.http_status_code
        @should_retry = error.should_retry?
      end

      # @return [Boolean] +should_retry?+ of the wrapped DeepL error, +false+ without one.
      def should_retry?
        @should_retry || false
      end
    end
  end
end
