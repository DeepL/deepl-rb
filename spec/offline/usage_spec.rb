# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL.usage' do
  it 'sends a GET with an empty JSON body' do
    stub_request(:get, url('/v2/usage')).with(body: '{}', headers: json_headers)
                                        .to_return(usage_reply)
    DeepL.usage
  end

  it 'reports no exceeded quota while the count is below the limit' do
    stub_request(:get, url('/v2/usage')).to_return(reply(character_count: 42, character_limit: 100))

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
      expect(DeepL.usage).to have_attributes(
        character_count: 5_947_223, character_limit: 1_000_000_000_000,
        api_key_character_count: 636, api_key_character_limit: 1_000_000_000_000,
        speech_to_text_minutes_count: 30, speech_to_text_minutes_limit: 600,
        speech_to_speech_minutes_count: 12, speech_to_speech_minutes_limit: 600,
        start_time: Time.utc(2025, 5, 13, 9, 18, 42), end_time: Time.utc(2025, 6, 13, 9, 18, 42),
        to_s: '5947223 / 1000000000000'
      )
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

    expect(usage.character_count).to eq(180_118)
    expect(usage.character_limit).to eq(1_250_000)
    expect(usage.to_s).to eq('180118 / 1250000')
    expect(usage.quota_exceeded?).to be(false)
    DeepL::Resources::Usage::PRO_FIELDS.each { |field| expect(usage.public_send(field)).to be_nil }
  end

  it 'keeps the positional constructor working' do
    usage = DeepL::Resources::Usage.new(1, 10, nil, nil)

    expect([usage.character_count, usage.character_limit, usage.products]).to eq([1, 10, nil])
  end
end
