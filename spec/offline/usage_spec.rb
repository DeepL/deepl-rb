# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'usage' do
  describe 'DeepL.usage' do
    it 'sends a GET with an empty JSON body' do
      stub_request(:get, url('/v2/usage')).with(body: '{}', headers: json_headers)
                                          .to_return(usage_reply)
      DeepL.usage
    end

    it 'reports no exceeded quota while the count is below the limit' do
      stub_request(:get, url('/v2/usage'))
        .to_return(reply(character_count: 42, character_limit: 100))

      expect(DeepL.usage.quota_exceeded?).to be(false)
    end

    it 'reports an exceeded quota when the count reaches the limit' do
      stub_request(:get,
                   url('/v2/usage')).to_return(reply(character_count: 100, character_limit: 100))

      expect(DeepL.usage.quota_exceeded?).to be(true)
    end

    context 'with an API Pro response' do
      let(:pro_body) do
        {
          character_count: 5_947_223, character_limit: 1_000_000_000_000,
          products: [
            { product_type: 'write', billing_unit: 'characters', api_key_unit_count: 0,
              account_unit_count: 5643, api_key_character_count: 0, character_count: 5643 },
            { product_type: 'translate', billing_unit: 'characters', api_key_unit_count: 636,
              account_unit_count: 5_941_580, api_key_character_count: 636,
              character_count: 5_941_580 },
            { product_type: 'speechToText', billing_unit: 'minutes', api_key_unit_count: 30,
              account_unit_count: 30, api_key_character_count: 0, character_count: 0 },
            { product_type: 'speechToSpeech', billing_unit: 'minutes', api_key_unit_count: 12,
              account_unit_count: 12, api_key_character_count: 0, character_count: 0 }
          ],
          api_key_character_count: 636, api_key_character_limit: 1_000_000_000_000,
          speech_to_text_milliseconds_count: 0, speech_to_text_milliseconds_limit: 0,
          speech_to_text_minutes_count: 30, speech_to_text_minutes_limit: 600,
          speech_to_speech_minutes_count: 12, speech_to_speech_minutes_limit: 600,
          start_time: '2025-05-13T09:18:42Z', end_time: '2025-06-13T09:18:42Z'
        }
      end

      before { stub_request(:get, url('/v2/usage')).to_return(reply(pro_body)) }

      it 'parses the per-key, speech and billing period fields' do
        usage = DeepL.usage

        expect(usage).to have_attributes(
          character_count: 5_947_223, character_limit: 1_000_000_000_000,
          start_time: Time.utc(2025, 5, 13, 9, 18, 42), end_time: Time.utc(2025, 6, 13, 9, 18, 42),
          to_s: '5947223 / 1000000000000'
        )
        expect(usage.character).to have_attributes(count: 5_947_223, limit: 1_000_000_000_000)
        expect(usage.api_key_character).to have_attributes(count: 636, limit: 1_000_000_000_000)
        expect([usage.speech_to_text_minutes, usage.speech_to_speech_minutes].map(&:to_s))
          .to eq(['30 of 600', '12 of 600'])
      end

      it 'parses the per-product usage' do
        products = DeepL.usage.products

        expect(products).to all(be_a(DeepL::Resources::UsageProduct))
        expect(products.map(&:product_type)).to eq(%w[write translate speechToText speechToSpeech])
        expect(products.map(&:billing_unit)).to eq(%w[characters characters minutes minutes])
        expect(products.map(&:api_key_unit_count)).to eq([0, 636, 30, 12])
        expect(products.map(&:account_unit_count)).to eq([5643, 5_941_580, 30, 12])
      end
    end

    it 'leaves the API Pro fields nil for a Free response' do
      stub_request(:get, url('/v2/usage')).to_return(reply(character_count: 180_118,
                                                           character_limit: 1_250_000))
      usage = DeepL.usage

      expect(usage.character).to have_attributes(count: 180_118, limit: 1_250_000)
      expect(usage.to_s).to eq('180118 / 1250000')
      expect(usage.quota_exceeded?).to be(false)
      DeepL::Resources::Usage::KEYWORD_FIELDS.each do |field|
        expect(usage.public_send(field)).to be_nil
      end
    end

    it 'parses the document and team document usage' do
      stub_request(:get, url('/v2/usage')).to_return(
        reply(character_count: 1, character_limit: 100, document_count: 5, document_limit: 5,
              team_document_count: 2, team_document_limit: 10)
      )
      usage = DeepL.usage

      expect(usage.document).to have_attributes(count: 5, limit: 5, limit_reached?: true)
      expect(usage.team_document).to have_attributes(count: 2, limit: 10, limit_reached?: false)
      expect(usage.any_limit_reached?).to be(true)
    end

    it 'does not count the API Pro usage types in any_limit_reached?' do
      stub_request(:get, url('/v2/usage')).to_return(
        reply(character_count: 1, character_limit: 100, api_key_character_count: 50,
              api_key_character_limit: 50)
      )
      usage = DeepL.usage

      expect(usage.api_key_character.limit_reached?).to be(true)
      expect(usage.any_limit_reached?).to be(false)
    end

    it 'ignores an unparseable billing period and malformed products' do
      stub_request(:get, url('/v2/usage')).to_return(
        reply(character_count: 20, character_limit: 500_000, start_time: 'not a timestamp',
              end_time: '', products: [{ product_type: 'translate' }, 'not an object'])
      )
      usage = DeepL.usage

      expect(usage.character_count).to eq(20)
      expect([usage.start_time, usage.end_time]).to eq([nil, nil])
      expect(usage.products.map(&:product_type)).to eq(['translate'])
    end

    it 'keeps the positional constructor working' do
      usage = DeepL::Resources::Usage.new(1, 10, nil, nil)

      expect([usage.character_count, usage.character_limit, usage.products]).to eq([1, 10, nil])
    end
  end

  describe DeepL::Client do
    let(:client) { described_class.new('client-key', server_url: 'https://client.example.test') }

    it '#get_usage sends GET /v2/usage and parses the usage' do
      stub_request(:get, 'https://client.example.test/v2/usage')
        .with(headers: { 'Authorization' => 'DeepL-Auth-Key client-key' })
        .to_return(reply(character_count: 42, character_limit: 100, document_count: 5,
                         document_limit: 5))

      usage = client.get_usage

      expect(usage.character).to have_attributes(count: 42, limit: 100, limit_reached?: false)
      expect(usage.document).to have_attributes(count: 5, limit: 5)
      expect([usage.any_limit_reached?, usage.team_document]).to eq([true, nil])
    end
  end
end
