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

      expect(DeepL.usage.character_count).to eq(1)
      expect(stub).to have_been_requested.twice
    end

    it 'retries a 500 reply' do
      stub = stub_usage(reply({}, 500), usage_reply)

      DeepL.usage

      expect(stub).to have_been_requested.twice
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

  describe 'logging' do
    let(:log) { StringIO.new }

    it 'logs the request and the retry' do
      DeepL.configuration.logger = Logger.new(log)
      stub_usage(reply({}, 429), usage_reply)

      DeepL.usage

      expect(log.string).to include('Request to the DeepL API: GET /v2/usage')
                        .and include('Starting retry 1 for request GET /v2/usage')
    end
  end
end
