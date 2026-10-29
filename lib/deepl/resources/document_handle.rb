# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Resources
    class DocumentHandle < Base
      attr_reader :document_id, :document_key

      # +api+ is the connection the handle was created with; status queries go through it.
      def initialize(document_id, document_key, *args, api: nil)
        super(*args)

        @document_id = document_id
        @document_key = document_key
        @api = api
      end

      def to_s
        "DocumentHandle: ID: #{document_id} - Key: #{document_key}"
      end

      # Leaves out the connection, which holds the auth key.
      def inspect
        "#<#{self.class.name} document_id=#{document_id.inspect}>"
      end

      ##
      # For this DocumentHandle, waits until the document translation is finished (done or
      # failed) and returns the final status of the document. Stops early only if the
      # deprecated +max_doc_status_queries+ is configured.
      #
      # @deprecated Use DeepL::Client#translate_document_wait_until_done instead.
      # @return [DeepL::Resources::DocumentTranslationStatus] Final status of the document
      #                                                       translation.
      def wait_until_document_translation_finished
        Deprecation.warn_once('DocumentHandle#wait_until_document_translation_finished',
                              '[DEPRECATION] DeepL::Resources::DocumentHandle#' \
                              'wait_until_document_translation_finished is deprecated, use ' \
                              'DeepL::Client#translate_document_wait_until_done instead.')
        Utils::DocumentPoller.wait_until_finished(
          api, self, max_queries: api.configuration.max_doc_status_queries
        )
      end

      private

      # Handles created without a connection fall back to the deprecated module configuration.
      def api
        @api || DeepL.send(:module_api)
      end
    end
  end
end
