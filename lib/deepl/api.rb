# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  class API
    attr_reader :configuration, :http_client, :http_client_options

    # +client:+ is true for the API of a DeepL::Client or DeepL::AdminClient, whose errors differ
    # from those of the module-level API until the next major version. @api private
    def initialize(configuration, http_client_options = nil, client: false)
      @configuration = configuration
      @client = client
      configuration.validate!
      @http_client_options = http_client_options
      @http_client = if http_client_options
                       Utils::HTTPClientBuilder.build(configuration.host, http_client_options)
                     else
                       default_http_client(configuration.host)
                     end
    end

    # @api private
    def client?
      @client
    end

    # +options+ are the HTTPClientOptions the client was built with; their timeouts take
    # precedence over the per-attempt timeout.
    def update_http_client(client, options = nil)
      @http_client = client
      @http_client_options = options
    end

    private

    # Without explicit options Net::HTTP applies the proxy from the environment (+http_proxy+).
    def default_http_client(host)
      uri = URI(host)
      client = Net::HTTP.new(uri.host, uri.port)
      client.use_ssl = uri.scheme == 'https'
      Utils::HTTPClientBuilder.disable_lenient_defaults(client)
    end
  end
end
