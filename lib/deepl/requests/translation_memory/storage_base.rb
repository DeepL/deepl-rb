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
      # API, so they are requested over their own connection and send only the User-Agent: neither
      # the DeepL `Authorization` header nor other caller headers. That connection uses the same
      # proxy, SSL and timeout options as the API connection. Every non-2xx response raises a
      # plain DeepL::Exceptions::Error.

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
          Utils::HTTPClientBuilder.disable_lenient_defaults(client)
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

        # Only the User-Agent: the caller's from the configured +headers+, else the library's.
        def headers
          caller_agent = (api.configuration.headers || {}).find do |name, _|
            name.to_s.casecmp?('user-agent')
          end
          { 'User-Agent' => caller_agent ? caller_agent.last : api.configuration.user_agent }
        end
      end
    end
  end
end
