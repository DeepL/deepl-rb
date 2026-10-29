# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  class HTTPClientOptions
    attr_reader :proxy, :send_platform_info, :enable_ssl_verification, :cert_path, :open_timeout,
                :read_timeout, :write_timeout, :ssl_timeout

    def initialize(proxy = {}, cert_path = nil, enable_ssl_verification: true, open_timeout: nil, # rubocop:disable Metrics/ParameterLists
                   read_timeout: nil, write_timeout: nil, ssl_timeout: nil)
      @proxy = proxy
      @enable_ssl_verification = enable_ssl_verification
      @cert_path = cert_path
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @write_timeout = write_timeout
      @ssl_timeout = ssl_timeout
    end

    # Hides the user info of a proxy URL: +http://user:pass@host:port+ becomes
    # +http://[REDACTED]@host:port+.
    def self.redact_proxy(proxy)
      if proxy.is_a?(String)
        return proxy.sub(%r{\A([a-z][a-z0-9+.-]*://)?[^/@]*@}i,
                         '\1[REDACTED]@')
      end
      return proxy unless proxy.is_a?(Hash)

      proxy.to_h { |key, value| [key, key.to_s =~ /user|pass/i ? '[REDACTED]' : value] }
    end

    # Leaves out the proxy credentials.
    def inspect
      shown = { proxy: self.class.redact_proxy(proxy), cert_path: cert_path,
                enable_ssl_verification: enable_ssl_verification, open_timeout: open_timeout,
                read_timeout: read_timeout, write_timeout: write_timeout, ssl_timeout: ssl_timeout }
      "#<#{self.class.name} #{shown.map { |name, value| "#{name}=#{value.inspect}" }.join(', ')}>"
    end
  end
end
