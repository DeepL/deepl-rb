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

      ##
      # For this DocumentHandle, waits until the document translation is finished and returns the
      # final status of the document.
      #
      # @return [DeepL::Resources::DocumentTranslationStatus] Final status of the document
      #                                                       translation.

      def wait_until_document_translation_finished
        doc_status = nil
        max_tries = max_doc_status_queries
        num_tries = 0
        loop do
          num_tries += 1
          sleep(calculate_waiting_time(doc_status)) unless doc_status.nil?
          doc_status = DocumentApi.new(api).get_status(self)
          break if doc_status.finished? || num_tries > max_tries
        end
        doc_status
      end

      private

      def calculate_waiting_time(_resp)
        # ignore _resp.seconds_remaining for now, while it is unreliable
        5
      end

      # Handles created without a connection fall back to the deprecated module configuration.
      def api
        @api || DeepL.send(:module_api)
      end

      def max_doc_status_queries
        configured_value = api.configuration.max_doc_status_queries
        return configured_value unless configured_value.nil?

        10
      end
    end
  end
end
