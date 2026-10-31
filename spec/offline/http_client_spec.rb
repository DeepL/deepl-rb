# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'logger'
require 'stringio'
require_relative 'offline_helper'

describe 'DeepL HTTP client' do
  def stub_usage(*replies)
    stub_request(:get, url('/v2/usage')).to_return(*replies)
  end

  describe 'retries' do
    it 'retries a 429 reply' do
      stub = stub_usage(reply({}, 429), usage_reply)

      DeepL.usage
      expect(stub).to have_been_requested.twice
    end

    it 'retries a 500 reply' do
      stub = stub_usage(reply({}, 500), usage_reply)

      DeepL.usage

      expect(stub).to have_been_requested.twice
    end

    it 'retries a 503 reply' do
      stub = stub_usage(reply({}, 503), usage_reply)

      DeepL.usage

      expect(stub).to have_been_requested.twice
    end

    it 'retries refused and reset connections, broken pipes and EOF' do
      [Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE, EOFError].each do |error|
        WebMock.reset!
        stub = stub_request(:get, url('/v2/usage')).to_raise(error).then.to_return(usage_reply)

        DeepL.usage

        expect(stub).to have_been_requested.twice
      end
    end

    it 'does not retry a TLS failure or a malformed response' do
      [OpenSSL::SSL::SSLError, Net::HTTPBadResponse].each do |error|
        WebMock.reset!
        stub = stub_request(:get, url('/v2/usage')).to_raise(error).then.to_return(usage_reply)

        expect { DeepL.usage }.to raise_error(DeepL::Exceptions::ConnectionError) { |e|
          expect([e.cause, e.should_retry?]).to match([be_a(error), false])
        }
        expect(stub).to have_been_requested.once
      end
    end

    it 'raises a failed proxy CONNECT as a ConnectionError without retrying' do
      error = Net::HTTPClientException.new('407 "Proxy Authentication Required"', nil)
      stub = stub_request(:get, url('/v2/usage')).to_raise(error).then.to_return(usage_reply)

      expect { DeepL.usage }.to raise_error(DeepL::Exceptions::ConnectionError) { |e|
        expect([e.cause, e.should_retry?]).to match([be_a(Net::HTTPClientException), false])
      }
      expect(stub).to have_been_requested.once
    end

    it 'retries a body shorter than its Content-Length and raises a ConnectionError' do
      short = { status: 200, body: '{"char', headers: { 'Content-Length' => '46' } }
      stub = stub_usage(short)

      expect { DeepL.usage }.to raise_error(DeepL::Exceptions::ConnectionError) { |e|
        expect([e.cause, e.should_retry?]).to match([be_a(EOFError), true])
      }
      expect(stub).to have_been_requested.times(3)
    end

    it 'does not let Net::HTTP re-send a request or accept a short body' do # rubocop:disable RSpec/ExampleLength
      clients = []
      allow(Net::HTTP).to receive(:new).and_wrap_original do |new, *args|
        new.call(*args).tap { clients << _1 }
      end
      upload_url = 'https://storage.example.test/upload?sig=abc'
      stub_request(:put, upload_url).to_return(status: 200)

      [nil, DeepL::HTTPClientOptions.new({})].each do |options|
        client = DeepL::Client.new('abc', http_client_options: options)
        client.upload_translation_memory_file(upload_url, 'tmx')
      end

      expect(clients.map(&:max_retries)).to eq([0, 0, 0, 0])
      # Net::HTTP#ignore_eof= exists from net-http 0.3 (Ruby 3.2).
      next unless Net::HTTP.method_defined?(:ignore_eof=)

      expect(clients.map(&:ignore_eof)).to eq([false, false, false, false])
    end

    it 'trims the auth key' do
      DeepL.configuration.auth_key = " k \n"
      stub_request(:get, url('/v2/usage')).with(headers: auth_headers).to_return(usage_reply)

      DeepL.usage
    end

    it 'retries a network error' do
      stub = stub_request(:get, url('/v2/usage')).to_raise(SocketError).then.to_return(usage_reply)

      DeepL.usage

      expect(stub).to have_been_requested.twice
    end

    it 'retries a timeout' do
      stub = stub_request(:get, url('/v2/usage')).to_timeout.then.to_return(usage_reply)

      DeepL.usage

      expect(stub).to have_been_requested.twice
    end

    it 'raises the network error after max_network_retries retries' do
      stub = stub_request(:get, url('/v2/usage')).to_timeout

      expect { DeepL.usage }.to raise_error(DeepL::Exceptions::ConnectionError) { |error|
        expect(error.cause).to be_a(Net::OpenTimeout)
      }
      expect(stub).to have_been_requested.times(3)
    end

    it 'raises LimitExceeded after max_network_retries retries' do
      stub = stub_usage(reply({}, 429))

      expect { DeepL.usage }.to raise_error(DeepL::Exceptions::LimitExceeded)
      expect(stub).to have_been_requested.times(3)
    end

    it 'does not retry when max_network_retries is 0' do
      DeepL.configuration.max_network_retries = 0
      stub = stub_usage(reply({}, 429))

      expect { DeepL.usage }.to raise_error(DeepL::Exceptions::LimitExceeded)
      expect(stub).to have_been_requested.once
    end
  end

  describe '.with_session' do
    it 'runs the block without client options' do
      stub = stub_usage(usage_reply)

      DeepL.with_session { DeepL.usage }

      expect(stub).to have_been_requested.once
    end

    it 'raises ArgumentError without a block' do
      expect { DeepL.with_session }.to raise_error(ArgumentError, /requires a block/)
    end

    it 'applies the proxy and the timeouts to the client inside the block' do
      options = DeepL::HTTPClientOptions.new({ 'proxy_addr' => 'proxy.example.test',
                                               'proxy_port' => 8080 },
                                             nil, open_timeout: 3, read_timeout: 4)
      stub_usage(usage_reply)

      client = DeepL.with_session(options) do
        DeepL.usage
        DeepL.api.http_client
      end

      expect([client.proxy_address, client.proxy_port, client.open_timeout, client.read_timeout])
        .to eq(['proxy.example.test', 8080, 3, 4])
    end

    it 'enables SSL from the URL scheme and verifies certificates unless disabled' do
      session_client = lambda do |host, verify|
        DeepL.configuration.host = host
        options = DeepL::HTTPClientOptions.new({}, nil, enable_ssl_verification: verify)
        DeepL.with_session(options) { DeepL.api.http_client }
      end

      expect(session_client.call('http://localhost:3000', true)).to have_attributes(use_ssl?: false)
      expect(session_client.call('https://api.deepl.com', false))
        .to have_attributes(use_ssl?: true, verify_mode: OpenSSL::SSL::VERIFY_NONE)
    end

    it 'uses no proxy when only the proxy address is given' do
      options = DeepL::HTTPClientOptions.new({ 'proxy_addr' => 'proxy.example.test' })

      expect(DeepL.with_session(options) { DeepL.api.http_client }.proxy_address).to be_nil
    end

    it 'raises ConnectionError when the session cannot connect' do
      http = Net::HTTP.new('unresolvable.invalid', 443)
      allow(http).to receive(:start).and_raise(SocketError, 'getaddrinfo: Name not known')
      allow(DeepL::Utils::HTTPClientBuilder).to receive(:build).and_return(http)

      expect { DeepL.with_session { nil } }
        .to raise_error(DeepL::Exceptions::ConnectionError) { |e| expect(e.cause).to be_a(SocketError) }
    end

    it 'opens the session connection with the configured timeout' do
      DeepL.configuration.timeout = 4
      options = DeepL::HTTPClientOptions.new({}, nil, read_timeout: 7)

      client = DeepL.with_session(options) { DeepL.api.http_client }

      expect([client.open_timeout, client.read_timeout]).to eq([4, 7])
    end

    it 'restores the previous client when the block ends' do
      previous = DeepL.api.http_client
      options = DeepL::HTTPClientOptions.new({ 'proxy_addr' => 'proxy.example.test',
                                               'proxy_port' => 8080 })
      stub_usage(usage_reply)

      DeepL.with_session(options) { DeepL.usage }

      expect(DeepL.api.http_client).to equal(previous)
      expect(DeepL.api.http_client.proxy_address).to be_nil
      expect(DeepL.http_client).to be_nil
    end

    it 'restores the previous client when the block raises' do
      previous = DeepL.api.http_client

      expect { DeepL.with_session { raise 'boom' } }.to raise_error('boom')
      expect(DeepL.api.http_client).to equal(previous)
    end
  end

  describe 'logging' do
    let(:log) { StringIO.new }

    it 'logs the request and the retry' do
      DeepL.configuration.logger = Logger.new(log)
      stub_usage(reply({}, 429), usage_reply)

      DeepL.usage

      expect(log.string).to include('Request to the DeepL API: GET /v2/usage')
                        .and include('Starting retry 1 for request GET /v2/usage')
    end

    context 'with a debug logger' do
      before do
        DeepL.configuration.auth_key = 'sdktest-secret-key'
        DeepL.configuration.logger = Logger.new(log, level: Logger::DEBUG)
      end

      def expect_key_redacted
        expect(log.string).not_to include('sdktest-secret-key')
        expect(log.string).to include('DeepL-Auth-Key [REDACTED]')
      end

      it 'redacts the auth key in the request details' do
        stub_usage(usage_reply)

        DeepL.usage

        expect_key_redacted
      end

      it 'redacts the auth key in the details of a request type that overrides them' do
        stub_request(:post, url('/v2/translate'))
          .to_return(reply(translations: [{ text: 'Hallo' }]))

        DeepL.translate('Hello', nil, 'DE')

        expect_key_redacted
      end

      it 'redacts an Authorization header given with another casing' do
        stub_request(:post, url('/v2/translate'))
          .to_return(reply(translations: [{ text: 'Hallo' }]))

        other = { 'authorization' => 'DeepL-Auth-Key sdktest-other-key' }
        DeepL.translate('Hello', nil, 'DE', {}, other)

        expect(log.string).not_to include('sdktest-other-key')
      end
    end
  end

  describe 'headers' do
    it 'lets per-call headers replace the Authorization header in any casing' do
      stub_request(:post, url('/v2/translate'))
        .with(headers: { 'Authorization' => 'DeepL-Auth-Key other', 'X-Custom' => 'v' })
        .to_return(reply(translations: [{ text: 'Hallo' }]))

      DeepL.translate('Hello', nil, 'DE', {}, { 'authorization' => 'DeepL-Auth-Key other',
                                                'X-Custom' => 'v' })
    end

    it "keeps the SDK's Host and Content-Type over per-call headers" do
      sdk_host = ->(request) { [nil, 'api.deepl.com'].include?(request.headers['Host']) }
      stub_request(:post, 'https://api.deepl.com/v2/translate')
        .with(headers: { 'Content-Type' => 'application/json' }, &sdk_host)
        .to_return(reply(translations: [{ text: 'Hallo' }]))

      DeepL.translate('Hello', nil, 'DE', {}, { 'host' => 'other.example.test',
                                                'content-type' => 'text/plain' })
    end
  end

  describe 'HTTPClientBuilder' do
    it 'uses the proxy only when both address and port are given' do
      partial = DeepL::HTTPClientOptions.new({ 'proxy_addr' => 'proxy.example.test' })
      full = DeepL::HTTPClientOptions.new({ 'proxy_addr' => 'proxy.example.test',
                                            'proxy_port' => 8080 })
      build = ->(options) { DeepL::Utils::HTTPClientBuilder.build('https://api.deepl.com', options) }

      expect(build.call(partial).proxy_address).to be_nil
      expect(build.call(full).proxy_address).to eq('proxy.example.test')
    end
  end
end
