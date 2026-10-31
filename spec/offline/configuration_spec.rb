# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'logger'
require_relative 'offline_helper'

describe DeepL::Configuration do
  subject(:config) { described_class.new(attributes) }

  let(:attributes) { {} }

  around do |tests|
    tmp_env = ENV.to_hash
    ENV.clear
    tests.call
    ENV.replace(tmp_env)
  end

  describe '#initialize' do
    context 'when using default configuration attributes' do
      it 'uses default attributes' do
        expect(config.auth_key).to eq(ENV.fetch('DEEPL_AUTH_KEY', nil))
        expect(config.host).to eq('https://api.deepl.com')
        expect(config.max_doc_status_queries).to be_nil
        expect(config.version).to eq('v2')
        expect(config.timeout).to eq(60.0)
      end

      it 'sends platform information' do
        expect(config.user_agent).to include('deepl-ruby/')
        expect(config.user_agent).to include('(')
        expect(config.user_agent).to include(')')
        expect(config.user_agent).to include(' ruby/')
      end
    end

    context 'when using custom configuration attributes' do
      let(:logger) { Logger.new($stdout) }
      let(:attributes) { { auth_key: 'SAMPLE', host: 'https://api-free.deepl.com', logger: logger, max_doc_status_queries: 42, max_network_retries: 43, version: 'v1' } }

      it 'uses custom attributes' do
        expect(config.auth_key).to eq(attributes[:auth_key])
        expect(config.host).to eq(attributes[:host])
        expect(config.max_doc_status_queries).to eq(attributes[:max_doc_status_queries])
        expect(config.max_network_retries).to eq(attributes[:max_network_retries])
        expect(config.version).to eq(attributes[:version])
      end
    end

    context 'when the environment provides the key and the server URL' do
      before do
        ENV['DEEPL_AUTH_KEY'] = 'env-key'
        ENV['DEEPL_SERVER_URL'] = 'https://api.example.test'
      end

      it 'uses the environment values' do
        expect(config.auth_key).to eq('env-key')
        expect(config.host).to eq('https://api.example.test')
      end

      it 'prefers the given attributes' do
        config = described_class.new(auth_key: 'given', host: 'https://given.example.test')
        expect([config.auth_key, config.host]).to eq(%w[given https://given.example.test])
      end
    end

    context 'when using a free key' do
      let(:attributes) { { auth_key: '123e4567-e89b-12d3-a456-426614174000:fx' } }

      it 'uses the free API URL' do
        expect(config.host).to eq('https://api-free.deepl.com')
      end
    end

    context 'when the free key is set after the configuration was created' do
      it 'uses the free API URL' do
        config.auth_key = 'abc:fx'

        expect(config.host).to eq('https://api-free.deepl.com')
      end
    end

    context 'when the free key has surrounding whitespace' do
      let(:attributes) { { auth_key: 'abc:fx ' } }

      it 'uses the free API URL' do
        expect(config.host).to eq('https://api-free.deepl.com')
      end
    end

    context 'when using a pro key' do
      let(:attributes) { { auth_key: '123e4567-e89b-12d3-a456-426614174000' } }

      it 'uses the pro API URL' do
        expect(config.host).to eq('https://api.deepl.com')
      end
    end

    context 'when opting out of sending platform info' do
      subject(:config) { described_class.new(attributes, nil, nil, false) }

      it 'does not send platform information' do
        expect(config.user_agent).to include('deepl-ruby/')
        expect(config.user_agent).not_to include('(')
        expect(config.user_agent).not_to include(')')
        expect(config.user_agent).not_to include(' ruby/')
      end
    end

    context 'when registering an app and sending platform info' do
      subject(:config) { described_class.new(attributes, 'MyTestApp', '0.1.3', true) }

      it 'sends platform and app info' do
        expect(config.user_agent).to include('deepl-ruby/')
        expect(config.user_agent).to include('(')
        expect(config.user_agent).to include(')')
        expect(config.user_agent).to include(' ruby/')
        expect(config.user_agent).to include('MyTestApp/0.1.3')
      end
    end

    context 'when registering an app and not sending platform info' do
      subject(:config) { described_class.new(attributes, 'MyTestApp', '0.1.3', false) }

      it 'sends app, but not platform info' do
        expect(config.user_agent).to include('deepl-ruby/')
        expect(config.user_agent).not_to include('(')
        expect(config.user_agent).not_to include(')')
        expect(config.user_agent).not_to include(' ruby/')
        expect(config.user_agent).to include('MyTestApp/0.1.3')
      end
    end
  end

  describe '#validate!' do
    let(:auth_message) { 'auth_key not provided' }

    context 'when the auth key is empty' do
      let(:attributes) { { auth_key: '' } }

      it 'raises an error' do
        expect { config.validate! }.to raise_error(DeepL::Exceptions::Error, auth_message)
      end
    end

    context 'when the auth key is blank' do
      let(:attributes) { { auth_key: "  \n" } }

      it 'raises an error' do
        expect { config.validate! }.to raise_error(DeepL::Exceptions::Error, auth_message)
      end
    end

    context 'when the auth key is set' do
      let(:attributes) { { auth_key: 'not-empty' } }

      it 'does not raise an error' do
        expect { config.validate! }.not_to raise_error
      end
    end
  end
end
