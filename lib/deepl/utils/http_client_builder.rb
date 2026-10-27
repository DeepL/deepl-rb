# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    module HTTPClientBuilder
      extend self

      ##
      # Builds an unstarted Net::HTTP client for +host+ configured with +options+.
      #
      # @param [String] host Base URL of the API.
      # @param [DeepL::HTTPClientOptions] options Proxy, SSL and timeout options.
      # @return [Net::HTTP]
      def build(host, options) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        proxy = options.proxy
        has_proxy = proxy&.key?('proxy_addr') && proxy.key?('proxy_port')
        uri = URI(host)
        http = Net::HTTP.new(uri.host, uri.port, has_proxy ? proxy['proxy_addr'] : nil,
                             has_proxy ? proxy['proxy_port'] : nil)
        http.use_ssl = uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless options.enable_ssl_verification
        http.ca_file = options.cert_path if options.cert_path
        http.open_timeout = options.open_timeout unless options.open_timeout.nil?
        http.read_timeout = options.read_timeout unless options.read_timeout.nil?
        http.write_timeout = options.write_timeout unless options.write_timeout.nil?
        http.ssl_timeout = options.ssl_timeout unless options.ssl_timeout.nil?
        http
      end
    end
  end
end
