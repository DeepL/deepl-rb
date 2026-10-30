# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    module HTTPClientBuilder
      extend self

      ##
      # Builds an unstarted Net::HTTP client for +host+ configured with +options+. Net::HTTP does
      # not retry on its own (+max_retries+ 0): only the library's retries apply.
      #
      # @param [String] host Base URL of the API.
      # @param [DeepL::HTTPClientOptions] options Proxy, SSL and timeout options.
      # @return [Net::HTTP]
      def build(host, options) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        uri = URI(host)
        http = Net::HTTP.new(uri.host, uri.port, *proxy_arguments(options.proxy))
        http.use_ssl = uri.scheme == 'https'
        disable_lenient_defaults(http)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless options.enable_ssl_verification
        http.ca_file = options.cert_path if options.cert_path
        http.open_timeout = options.open_timeout unless options.open_timeout.nil?
        http.read_timeout = options.read_timeout unless options.read_timeout.nil?
        http.write_timeout = options.write_timeout unless options.write_timeout.nil?
        http.ssl_timeout = options.ssl_timeout unless options.ssl_timeout.nil?
        http
      end

      ##
      # Net::HTTP would re-send idempotent requests once on its own, outside max_retries, and would
      # return a body shorter than its Content-Length as complete (+ignore_eof+, net-http 0.3+).
      def disable_lenient_defaults(http)
        http.max_retries = 0
        http.ignore_eof = false if http.respond_to?(:ignore_eof=)
        http
      end

      private

      # The proxy is either a URL string, e.g. +http://user:pass@proxy.example:8080+, or a hash
      # with +proxy_addr+ and +proxy_port+. Returns the proxy arguments of +Net::HTTP.new+.
      def proxy_arguments(proxy)
        if proxy.is_a?(String) && !proxy.empty?
          proxy_uri = parse_proxy_url(proxy)

          return [proxy_uri.host, proxy_uri.port, decode(proxy_uri.user),
                  decode(proxy_uri.password)]
        end
        unless proxy.is_a?(Hash) && proxy.key?('proxy_addr') && proxy.key?('proxy_port')
          return [nil,
                  nil]
        end

        [proxy['proxy_addr'], proxy['proxy_port']]
      end

      # Error messages show the URL without its user info; the URI error, which repeats the URL,
      # is not kept as cause.
      def parse_proxy_url(proxy)
        proxy_uri = begin
          URI(proxy)
        rescue URI::InvalidURIError
          nil
        end
        return proxy_uri unless proxy_uri&.host.nil?

        raise ArgumentError, "Invalid proxy URL: #{HTTPClientOptions.redact_proxy(proxy)}",
              cause: nil
      end

      def decode(value)
        value && URI::DEFAULT_PARSER.unescape(value)
      end
    end
  end
end
