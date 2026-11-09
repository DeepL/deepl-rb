# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    # Builds the API connection of a DeepL::Client or DeepL::AdminClient from its constructor
    # options. Nothing is read from the environment or from module state.
    # @api private
    module ClientBuilder
      extend self

      def build_api(key, key_name:, server_url:, default_server_url:, headers:, max_retries:,
                    timeout:, proxy:, send_platform_info:, app_info:, http_client_options:, logger:) # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists
        key = key.to_s.strip
        raise ArgumentError, "#{key_name} must not be empty" if key.empty?

        host = host(server_url, default_server_url)
        headers = (headers || {}).to_h
        configuration = Configuration.new(
          auth_key: key, host: host, max_network_retries: max_retries,
          timeout: timeout, logger: logger,
          headers: headers.reject { |name, _| user_agent_header?(name) },
          user_agent: headers.find { |name, _| user_agent_header?(name) }&.last,
          send_platform_info: send_platform_info, app_info: AppInfo.from(app_info)
        )
        API.new(configuration, merge_proxy(http_client_options, proxy))
      end

      private

      # Validates the server URL and removes its trailing slashes: requests append /v2/... or
      # /v3/... to the host, so a trailing slash would give //v2/...
      def host(server_url, default_server_url)
        return default_server_url if server_url.nil?

        validate_server_url!(server_url)
        server_url.to_s.sub(%r{/+\z}, '')
      end

      # The server URL must be an absolute http or https URL with a host; a port and a path
      # prefix are allowed. +nil+ selects the default server.
      def validate_server_url!(server_url)
        return if server_url.nil?

        uri = begin
          URI.parse(server_url.to_s)
        rescue URI::InvalidURIError
          nil
        end
        return if uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?

        # The URL is left out of the message: it can contain credentials.
        raise ArgumentError, 'server_url must be an absolute http or https URL with a host',
              cause: nil
      end

      def user_agent_header?(name)
        name.to_s.casecmp?('user-agent')
      end

      def no_proxy?(proxy)
        proxy.nil? || (proxy.respond_to?(:empty?) && proxy.empty?)
      end

      def merge_proxy(options, proxy) # rubocop:disable Metrics/MethodLength
        return options if proxy.nil?
        if options && !no_proxy?(options.proxy)
          raise ArgumentError,
                'Set the proxy either with proxy: or in http_client_options:, not both'
        end
        return HTTPClientOptions.new(proxy) if options.nil?

        HTTPClientOptions.new(proxy, options.cert_path,
                              enable_ssl_verification: options.enable_ssl_verification,
                              open_timeout: options.open_timeout,
                              read_timeout: options.read_timeout,
                              write_timeout: options.write_timeout,
                              ssl_timeout: options.ssl_timeout)
      end
    end
  end
end
