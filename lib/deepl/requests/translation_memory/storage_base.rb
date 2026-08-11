# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      ##
      # Common behaviour of the requests to a pre-signed storage URL handed out by the API, such
      # as a translation memory upload or download URL. Those URLs point outside of the DeepL
      # API, so they are requested over their own connection and the DeepL `Authorization` header
      # is deliberately not sent.

      class StorageBase < DeepL::Requests::Base
        attr_reader :storage_url

        def initialize(api, storage_url, options = {}, additional_headers = {})
          super(api, options, additional_headers)
          if storage_url.nil? || storage_url.empty?
            raise Exceptions::Error, 'Storage URL must not be empty'
          end

          @storage_url = storage_url
        end

        private

        def http_client
          @http_client ||= begin
            client = Net::HTTP.new(uri.host, uri.port)
            client.use_ssl = uri.scheme == 'https'
            client
          end
        end

        def uri
          @uri ||= URI(storage_url)
        end

        def headers
          { 'User-Agent' => api.configuration.user_agent }.merge(@additional_headers)
        end
      end
    end
  end
end
