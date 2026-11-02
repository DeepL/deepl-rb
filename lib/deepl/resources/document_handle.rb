# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Resources
    class DocumentHandle < Base
      attr_reader :document_id, :document_key

      # The +api:+ keyword is kept for compatibility and not used.
      # A handle for a stored ID and key needs only those two: +DocumentHandle.new(id, key)+.
      def initialize(document_id, document_key, request = nil, response = nil, api: nil)
        super(request, response)

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
    end
  end
end
