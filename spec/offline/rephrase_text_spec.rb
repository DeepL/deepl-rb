# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL::Client#rephrase_text' do
  def stub_rephrase(body = nil)
    request = stub_request(:post, url('/v2/write/rephrase'))
    request = request.with(body: body, headers: json_headers) unless body.nil?
    request
  end

  it 'sends only the text when no other argument is given' do
    stub_rephrase(text: ['Hello']).to_return(reply(improvements: [{ text: 'Hi' }]))
    api_client.rephrase_text('Hello')
  end

  it 'sends the target language, writing style and tone' do
    stub_rephrase(text: %w[a b], target_lang: 'en-GB', writing_style: 'business',
                  tone: 'diplomatic')
      .to_return(reply(improvements: [{ text: 'x' }, { text: 'y' }]))

    api_client.rephrase_text(%w[a b], 'en-GB', writing_style: 'business', tone: 'diplomatic')
  end

  it 'overrides built-in parameters with extra_body_parameters' do
    stub_rephrase(text: ['Hello'], target_lang: 'de', beta: true)
      .to_return(reply(improvements: [{ text: 'Hallo' }]))

    api_client.rephrase_text('Hello', 'en',
                             extra_body_parameters: { target_lang: 'de', beta: true })
  end

  it 'returns a text for a string' do
    stub_rephrase.to_return(reply(improvements: [{ text: 'Hi' }]))

    expect(api_client.rephrase_text('Hello')).to be_a(DeepL::Resources::Text)
  end

  it 'parses the target language of each improvement' do
    stub_rephrase.to_return(reply(improvements: [
                                    { text: 'x', detected_source_language: 'en',
                                      target_language: 'en-GB' }, { text: 'y', target_language: 1 }
                                  ]))

    expect(api_client.rephrase_text(%w[a b]).map(&:target_language)).to eq(['en-GB', nil])
  end

  it 'returns an array of texts for an array' do
    stub_rephrase.to_return(reply(improvements: [{ text: 'x' }, { text: 'y' }]))

    expect(api_client.rephrase_text(%w[a b]).map(&:class)).to eq([DeepL::Resources::Text] * 2)
  end

  [['Hello', []], [%w[a b], [{ text: 'x' }]]].each do |text, improvements|
    it "raises DeepL::Exceptions::Error for #{improvements.size} improvements of #{text.inspect}" do
      stub_rephrase.to_return(reply(improvements: improvements))

      expect { api_client.rephrase_text(text) }
        .to raise_error(an_instance_of(DeepL::Exceptions::Error), /expected \d improvements/)
    end
  end
end
