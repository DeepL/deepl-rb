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

      def initialize(message, handle)
        super(message)
        @handle = handle
        @document_handle = handle
      end
    end
  end
end
