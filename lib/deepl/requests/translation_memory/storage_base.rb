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
      # is deliberately not sent. That connection uses the same proxy, SSL and timeout options as
      # the API connection. Every non-2xx response raises a plain DeepL::Exceptions::Error.

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
          @http_client ||= if api.http_client_options
                             Utils::HTTPClientBuilder.build(storage_url, api.http_client_options)
                           else
                             default_http_client
                           end
        end

        def http_client_options_of(_client)
          api.http_client_options
        end

        def default_http_client
          client = Net::HTTP.new(uri.host, uri.port)
          client.use_ssl = uri.scheme == 'https'
          # Net::HTTP would re-send idempotent requests once on its own, outside max_retries.
          client.max_retries = 0
          client
        end

        def uri
          @uri ||= URI(storage_url)
        end

        # Storage responses are not DeepL API responses, so their statuses carry none of the API's
        # meanings: an expired URL replies 403, which is no authorization failure.
        def validate_response!(response, _request = nil)
          return if response.is_a?(Net::HTTPSuccess)

          status = response.code.to_i
          raise Exceptions::Error.new(
            "Request to the storage URL failed with HTTP status #{status}",
            http_status_code: status, should_retry: status == 429 || (500..599).cover?(status)
          )
        end

        def headers
          { 'User-Agent' => api.configuration.user_agent }.merge(@additional_headers)
        end
      end
    end
  end
end
