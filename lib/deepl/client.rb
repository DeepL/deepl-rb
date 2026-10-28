# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  ##
  # Client for the DeepL API. Every client owns its configuration and HTTP connection: two
  # clients never share options, and nothing is read from environment variables or from the
  # deprecated module-level configuration (+DeepL.configure+).
  #
  #   client = DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), app_info: { app_name: 'my-app',
  #                                                                         app_version: '1.2.3' })
  #
  # All methods may raise a +DeepL::Exceptions::Error+ or a subclass.
  class Client
    DEEPL_SERVER_URL = 'https://api.deepl.com'
    DEEPL_SERVER_URL_FREE = 'https://api-free.deepl.com'
    private_constant :DEEPL_SERVER_URL, :DEEPL_SERVER_URL_FREE

    ##
    # Returns true if +auth_key+ is a DeepL API Free key (it ends with +:fx+).
    #
    # @param [String, nil] auth_key Authentication key.
    # @return [Boolean]
    def self.free_account_auth_key?(auth_key)
      auth_key.to_s.strip.end_with?(':fx')
    end

    ##
    # @param [String] auth_key Authentication key, surrounding whitespace is removed.
    # @param [String, nil] server_url Base URL of the DeepL API, a path prefix is kept. Defaults
    #   to +https://api-free.deepl.com+ for Free keys (ending in +:fx+), else
    #   +https://api.deepl.com+.
    # @param [Hash] headers HTTP headers sent with every DeepL API request (not to pre-signed
    #   storage URLs). A +User-Agent+ replaces the library's; +Authorization+ cannot be replaced.
    # @param [Integer] max_retries Number of retries after the first attempt, for HTTP 429, any
    #   5xx and network failures.
    # @param [Numeric] timeout Timeout of each attempt in seconds, applied to opening the
    #   connection, reading and writing. A longer backoff interval takes precedence.
    # @param [String, nil] proxy Proxy URL, e.g. +http://user:password@proxy.example:8080+.
    # @param [Boolean] send_platform_info Whether to add the OS and Ruby versions to the
    #   +User-Agent+.
    # @param [DeepL::AppInfo, Hash, nil] app_info Your application's +app_name+ and
    #   +app_version+, added to the +User-Agent+.
    # @param [DeepL::HTTPClientOptions, nil] http_client_options Proxy, certificate, SSL
    #   verification and per-phase timeouts. Its timeouts take precedence over +timeout+.
    # @param [Logger, nil] logger Logger for requests and retries.
    # @raise [ArgumentError] If +auth_key+ is empty.
    def initialize(auth_key, server_url: nil, headers: {}, max_retries: 5, timeout: 10, # rubocop:disable Metrics/ParameterLists
                   proxy: nil, send_platform_info: true, app_info: nil, http_client_options: nil,
                   logger: nil)
      free = self.class.free_account_auth_key?(auth_key)
      default_server_url = free ? DEEPL_SERVER_URL_FREE : DEEPL_SERVER_URL
      @api = Utils::ClientBuilder.build_api(
        auth_key, key_name: 'auth_key', server_url: server_url,
                  default_server_url: default_server_url, headers: headers,
                  max_retries: max_retries, timeout: timeout, proxy: proxy,
                  send_platform_info: send_platform_info, app_info: app_info,
                  http_client_options: http_client_options, logger: logger
      )
    end

    def inspect
      "#<#{self.class.name} server_url=#{configuration.host}>"
    end

    private

    attr_reader :api

    def configuration
      api.configuration
    end
  end
end
