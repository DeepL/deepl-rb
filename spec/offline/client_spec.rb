# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::Client do
  # The operations are added to DeepL::Client separately; until then the client's connection is
  # exercised with the usage request.
  def usage(client)
    DeepL::Requests::Usage.new(client.send(:api)).request
  end

  def stub_usage(base = OfflineHelper::HOST, headers: {})
    stub = stub_request(:get, "#{base}/v2/usage")
    stub = stub.with(headers: headers) unless headers.empty?
    stub.to_return(usage_reply)
  end

  describe '#initialize' do
    it 'sends the trimmed auth key to the Pro server' do
      stub_usage(headers: { 'Authorization' => 'DeepL-Auth-Key abc' })

      usage(described_class.new("  abc \n"))
    end

    it 'sends a Free key to the Free server' do
      stub_usage('https://api-free.deepl.com',
                 headers: { 'Authorization' => 'DeepL-Auth-Key a:fx' })

      usage(described_class.new('a:fx'))
    end

    it 'keeps the path prefix of the server URL' do
      stub_usage('http://localhost:3000/proxy')

      usage(described_class.new('abc', server_url: 'http://localhost:3000/proxy'))
    end

    it 'reads no environment variables' do
      env = ENV.to_h.slice('DEEPL_AUTH_KEY', 'DEEPL_SERVER_URL')
      ENV['DEEPL_SERVER_URL'] = 'http://environment.example.test'
      stub_usage(headers: { 'Authorization' => 'DeepL-Auth-Key abc' })

      usage(described_class.new('abc'))
    ensure
      ENV.delete('DEEPL_SERVER_URL')
      ENV.update(env)
    end

    it 'rejects an empty or blank auth key' do
      ['', "  \t", nil].each do |key|
        expect { described_class.new(key) }.to raise_error(ArgumentError, /auth_key/)
      end
    end

    it 'does not show the auth key in inspect' do
      expect(described_class.new('secret-key').inspect).not_to include('secret-key')
    end

    it 'does not expose its connection or configuration' do
      client = described_class.new('abc')

      expect(client).not_to respond_to(:api)
      expect(client).not_to respond_to(:configuration)
    end
  end

  describe 'headers' do
    it 'sends the headers but keeps the Authorization header' do
      stub_usage(headers: { 'Authorization' => 'DeepL-Auth-Key abc', 'X-Custom' => 'v' })

      usage(described_class.new('abc', headers: { 'X-Custom' => 'v',
                                                  'authorization' => 'DeepL-Auth-Key other' }))
    end

    it 'replaces the User-Agent with the one in headers' do
      stub_usage(headers: { 'User-Agent' => 'my-agent/1' })

      usage(described_class.new('abc', headers: { 'user-agent' => 'my-agent/1' }))
    end

    it 'adds the app info to the User-Agent' do
      stub_usage(headers: { 'User-Agent' => %r{\Adeepl-ruby/[^ ]+ my-app/1\.2\z} })

      usage(described_class.new('abc', send_platform_info: false,
                                       app_info: { app_name: 'my-app', app_version: '1.2' }))
    end

    it 'never mixes the options of two clients' do
      stub_usage(headers: { 'Authorization' => 'DeepL-Auth-Key one', 'X-Client' => '1' })
      stub_usage('http://localhost:3000',
                 headers: { 'Authorization' => 'DeepL-Auth-Key two', 'X-Client' => '2' })

      usage(described_class.new('one', headers: { 'X-Client' => '1' }))
      usage(described_class.new('two', server_url: 'http://localhost:3000',
                                       headers: { 'X-Client' => '2' }))
    end
  end

  describe 'max_retries' do
    it 'retries as often as configured' do
      stub = stub_request(:get, url('/v2/usage')).to_return(reply({}, 429), usage_reply)

      usage(described_class.new('abc', max_retries: 1))
      expect(stub).to have_been_requested.twice
    end

    it 'does not retry with max_retries 0' do
      stub = stub_request(:get, url('/v2/usage')).to_return(reply({}, 503))

      client = described_class.new('abc', max_retries: 0)
      expect { usage(client) }.to raise_error(DeepL::Exceptions::ServerError)
      expect(stub).to have_been_requested.once
    end
  end

  describe 'timeout' do
    it 'applies the timeout to each attempt' do
      stub_usage
      client = described_class.new('abc', timeout: 3)

      usage(client)

      http = client.send(:api).http_client
      expect([http.open_timeout, http.read_timeout, http.write_timeout]).to eq([3.0, 3.0, 3.0])
    end

    it 'defaults to 10 seconds and keeps the timeouts of the HTTP client options' do
      stub_usage
      options = DeepL::HTTPClientOptions.new({}, nil, read_timeout: 7)
      client = described_class.new('abc', http_client_options: options)

      usage(client)

      http = client.send(:api).http_client
      expect([http.open_timeout, http.read_timeout, http.write_timeout]).to eq([10.0, 7, 10.0])
    end
  end

  describe 'proxy' do
    def http_client(**options)
      described_class.new('abc', **options).send(:api).http_client
    end

    it 'accepts a proxy URL with credentials' do
      expect(http_client(proxy: 'http://us%40r:p%3Ass@proxy.example.test:3128'))
        .to have_attributes(proxy_address: 'proxy.example.test', proxy_port: 3128,
                            proxy_user: 'us@r', proxy_pass: 'p:ss')
    end

    it 'combines the proxy URL with the other HTTP client options' do
      options = DeepL::HTTPClientOptions.new({}, nil, enable_ssl_verification: false)

      expect(http_client(proxy: 'http://proxy.example.test:3128', http_client_options: options))
        .to have_attributes(proxy_address: 'proxy.example.test',
                            verify_mode: OpenSSL::SSL::VERIFY_NONE)
    end

    it 'rejects a proxy in both proxy: and http_client_options:' do
      options = DeepL::HTTPClientOptions.new('http://other.example.test:1')

      expect { http_client(proxy: 'http://proxy.example.test:3128', http_client_options: options) }
        .to raise_error(ArgumentError, /proxy/)
    end

    it 'does not show the proxy credentials in inspect' do
      client = described_class.new('abc', proxy: 'http://u:secret@proxy.test:3128')

      expect(client.inspect).not_to include('secret')
      expect(client.send(:api).inspect).not_to include('secret')
      expect(client.send(:api).http_client_options.inspect).to include('proxy.test:3128')
    end

    it 'does not show the proxy credentials in the error for an invalid proxy URL' do
      ['u:secret@proxy.test:3128', 'http://u:secret@proxy test:3128'].each do |proxy|
        expect { described_class.new('abc', proxy: proxy) }
          .to raise_error(ArgumentError) { |e| expect(e.full_message).not_to include('secret') }
      end
    end
  end

  describe '.free_account_auth_key?' do
    it 'detects Free keys' do
      expect(%w[a:fx a].map { |key| described_class.free_account_auth_key?(key) })
        .to eq([true, false])
      expect(described_class.free_account_auth_key?(nil)).to be(false)
    end
  end
end
