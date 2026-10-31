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
                    timeout:, proxy:, send_platform_info:, app_info:, http_client_options:, logger:) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/ParameterLists
        key = key.to_s.strip
        raise ArgumentError, "#{key_name} must not be empty" if key.empty?

        headers = (headers || {}).to_h
        app_info = AppInfo.from(app_info)
        configuration = Configuration.new(
          { auth_key: key, host: server_url || default_server_url,
            max_network_retries: max_retries, timeout: timeout, logger: logger,
            headers: headers.reject { |name, _| user_agent_header?(name) },
            user_agent: headers.find { |name, _| user_agent_header?(name) }&.last },
          app_info&.app_name, app_info&.app_version, send_platform_info
        )
        API.new(configuration, merge_proxy(http_client_options, proxy), client: true)
      end

      private

      def user_agent_header?(name)
        name.to_s.casecmp?('user-agent')
      end

      def merge_proxy(options, proxy) # rubocop:disable Metrics/MethodLength
        return options if proxy.nil?
        if options && !(options.proxy.nil? || options.proxy.empty?)
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
