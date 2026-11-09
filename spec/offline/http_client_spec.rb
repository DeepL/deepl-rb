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

      api_client.get_usage
      expect(stub).to have_been_requested.twice
    end

    it 'retries a 500 reply' do
      stub = stub_usage(reply({}, 500), usage_reply)

      api_client.get_usage

      expect(stub).to have_been_requested.twice
    end

    it 'retries a 503 reply' do
      stub = stub_usage(reply({}, 503), usage_reply)

      api_client.get_usage

      expect(stub).to have_been_requested.twice
    end

    it 'retries refused and reset connections, broken pipes and EOF' do
      [Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EPIPE, EOFError].each do |error|
        WebMock.reset!
        stub = stub_request(:get, url('/v2/usage')).to_raise(error).then.to_return(usage_reply)

        api_client.get_usage

        expect(stub).to have_been_requested.twice
      end
    end

    it 'does not retry a TLS failure or a malformed response' do
      [OpenSSL::SSL::SSLError, Net::HTTPBadResponse].each do |error|
        WebMock.reset!
        stub = stub_request(:get, url('/v2/usage')).to_raise(error).then.to_return(usage_reply)

        expect { api_client.get_usage }
          .to raise_error(DeepL::Exceptions::ConnectionError) { expect(_1.cause).to be_a(error) }
        expect(stub).to have_been_requested.once
      end
    end

    it 'raises a failed proxy CONNECT without retrying' do
      error = Net::HTTPClientException.new('407 "Proxy Authentication Required"', nil)
      stub = stub_request(:get, url('/v2/usage')).to_raise(error).then.to_return(usage_reply)

      expect { api_client.get_usage }
        .to raise_error(DeepL::Exceptions::ConnectionError) { expect(_1.should_retry?).to be(false) }
      expect(stub).to have_been_requested.once
    end

    it 'retries a body shorter than its Content-Length and raises ConnectionError' do
      short = { status: 200, body: '{"char', headers: { 'Content-Length' => '46' } }
      stub = stub_usage(short)

      expect { api_client.get_usage }
        .to raise_error(DeepL::Exceptions::ConnectionError) { expect(_1.cause).to be_a(EOFError) }
      expect(stub).to have_been_requested.times(3)
    end

    context 'with a document to upload' do
      include_context 'with a temporary directory'

      # Path of each create and a call of it.
      let(:create_calls) do
        input, = create_text_document(temp_dir)
        { '/v2/glossaries' => -> { _1.create_glossary('g', 'EN', 'DE', { 'a' => 'b' }) },
          '/v3/glossaries' => lambda { |client|
            client.create_multilingual_glossary('g', [{ source_lang: 'EN', target_lang: 'DE',
                                                        entries: { 'a' => 'b' } }])
          },
          '/v3/spoken-terms' => -> { _1.create_spoken_terms('t', []) },
          '/v3/style_profiles' => -> { _1.create_style_profile('p') },
          '/v3/style_rules' => -> { _1.create_style_rule('r', 'en') },
          '/v3/style_rules/s-1/custom_instructions' =>
            -> { _1.create_style_rule_custom_instruction('s-1', 'l', 'p') },
          '/v2/document' => -> { _1.translate_document_upload(input, 'EN', 'DE') },
          '/v3/translation_memories/import' =>
            -> { _1.create_translation_memory_import('a.tmx', 1) },
          '/v3/translation_memories/tm-1/export' =>
            -> { _1.create_translation_memory_export('tm-1') } }
      end

      it 'does not retry a 500 reply on an operation that creates a resource' do
        create_calls.each do |path, call|
          stub = stub_request(:post, url(path)).to_return(reply({ message: 'Error' }, 500))

          expect { call.call(api_client) }
            .to raise_error(DeepL::Exceptions::ServerError) { expect(_1.should_retry?).to be(false) }
          expect(stub).to have_been_requested.once
        end
      end
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

    it 'retries a network error' do
      stub = stub_request(:get, url('/v2/usage')).to_raise(SocketError).then.to_return(usage_reply)

      api_client.get_usage

      expect(stub).to have_been_requested.twice
    end

    it 'retries a timeout' do
      stub = stub_request(:get, url('/v2/usage')).to_timeout.then.to_return(usage_reply)

      api_client.get_usage

      expect(stub).to have_been_requested.twice
    end

    it 'raises ConnectionError after max_retries retries, with the network error as cause' do
      stub = stub_request(:get, url('/v2/usage')).to_timeout

      expect { api_client.get_usage }
        .to raise_error(DeepL::Exceptions::ConnectionError) { expect(_1.cause).to be_a(Net::OpenTimeout) }
      expect(stub).to have_been_requested.times(3)
    end

    it 'raises LimitExceeded after max_retries retries' do
      stub = stub_usage(reply({}, 429))

      expect { api_client.get_usage }.to raise_error(DeepL::Exceptions::LimitExceeded)
      expect(stub).to have_been_requested.times(3)
    end

    it 'does not retry when max_retries is 0' do
      stub = stub_usage(reply({}, 429))

      expect { offline_client(max_retries: 0).get_usage }.to raise_error(DeepL::Exceptions::LimitExceeded)
      expect(stub).to have_been_requested.once
    end
  end

  describe 'logging' do
    let(:log) { StringIO.new }

    it 'logs the request and the retry' do
      stub_usage(reply({}, 429), usage_reply)

      offline_client(logger: Logger.new(log)).get_usage

      expect(log.string).to include('Request to the DeepL API: GET /v2/usage')
                        .and include('Starting retry 1 for request GET /v2/usage')
    end

    context 'with a debug logger' do
      def debug_client(headers = {})
        DeepL::Client.new('sdktest-secret-key', server_url: OfflineHelper::HOST,
                                                headers: headers, logger: Logger.new(log, level: Logger::DEBUG))
      end

      def expect_key_redacted
        expect(log.string).not_to include('sdktest-secret-key')
        expect(log.string).to include('DeepL-Auth-Key [REDACTED]')
      end

      it 'redacts the auth key in the request details' do
        stub_usage(usage_reply)

        debug_client.get_usage

        expect_key_redacted
      end

      it 'redacts the auth key in the details of a request type that overrides them' do
        stub_request(:post, url('/v2/translate'))
          .to_return(reply(translations: [{ text: 'Hallo' }]))

        debug_client.translate_text('Hello', nil, 'DE')

        expect_key_redacted
      end

      it 'redacts an Authorization header given with another casing' do
        stub_request(:post, url('/v2/translate'))
          .to_return(reply(translations: [{ text: 'Hallo' }]))

        debug_client({ 'authorization' => 'DeepL-Auth-Key sdktest-other-key' })
          .translate_text('Hello', nil, 'DE')

        expect(log.string).not_to include('sdktest-other-key')
      end
    end
  end

  describe 'headers' do
    it "keeps the SDK's Host and Content-Type over the configured headers" do
      sdk_host = ->(request) { [nil, 'api.deepl.com'].include?(request.headers['Host']) }
      stub_request(:post, 'https://api.deepl.com/v2/translate')
        .with(headers: { 'Content-Type' => 'application/json' }, &sdk_host)
        .to_return(reply(translations: [{ text: 'Hallo' }]))

      offline_client(headers: { 'host' => 'other.example.test', 'content-type' => 'text/plain' })
        .translate_text('Hello', nil, 'DE')
    end

    it 'sends no caller Content-Type with a request without a body' do
      stub_request(:get, url('/v2/usage'))
        .with { |request| !request.headers.key?('Content-Type') }.to_return(usage_reply)

      offline_client(headers: { 'content-type' => 'text/plain' })
        .get_usage
    end
  end

  describe 'HTTPClientBuilder' do
    it 'uses a proxy hash with address and port and rejects one with only the address' do
      partial = DeepL::HTTPClientOptions.new({ 'proxy_addr' => 'proxy.example.test' })
      full = DeepL::HTTPClientOptions.new({ 'proxy_addr' => 'proxy.example.test',
                                            'proxy_port' => 8080 })
      build = ->(options) { DeepL::Utils::HTTPClientBuilder.build('https://api.deepl.com', options) }

      expect { build.call(partial) }.to raise_error(ArgumentError, /proxy/)
      expect(build.call(full).proxy_address).to eq('proxy.example.test')
    end
  end
end
