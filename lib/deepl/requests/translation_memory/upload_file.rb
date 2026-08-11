# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class UploadFile < StorageBase
        DEFAULT_CONTENT_TYPE = 'application/xml'

        attr_reader :file_content, :content_type

        def initialize(api, upload_url, file_content, content_type = DEFAULT_CONTENT_TYPE)
          super(api, upload_url)
          @file_content = file_content
          @content_type = content_type || DEFAULT_CONTENT_TYPE
        end

        def request
          build_response(*execute_request_with_retries(put_request))
        end

        def details
          "HTTP Headers: #{headers}\nPayload #{file_content.bytesize} byte(s)"
        end

        def to_s
          "PUT #{uri.request_uri}"
        end

        private

        def put_request
          put_req = Net::HTTP::Put.new(uri.request_uri,
                                       headers.merge('Content-Type' => content_type))
          put_req.body = file_content
          put_req
        end

        def build_response(_, _)
          nil
        end
      end
    end
  end
end
