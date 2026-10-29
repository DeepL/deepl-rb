# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Document
      class Download < Base
        attr_reader :document_id, :document_key

        def initialize(api, document_id, document_key, output_file)
          super(api, {})
          @document_id = document_id
          @document_key = document_key
          @output_file = output_file
        end

        def request
          payload = { document_key: document_key }
          extract_file(*execute_request_with_retries(post_request(payload)))
        end

        def details
          "HTTP Headers: #{loggable_headers}\nPayload #{{ document_key: document_key }}"
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        # Binary mode: text mode would convert newlines on Windows and transcode the bytes when
        # Encoding.default_internal is set.
        def extract_file(_request, response)
          File.binwrite(@output_file, response.body)
        end

        def path
          "document/#{document_id}/result"
        end
      end
    end
  end
end
