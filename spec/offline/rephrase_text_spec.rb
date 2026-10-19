# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL.rephrase' do
  def stub_rephrase(body = nil)
    request = stub_request(:post, url('/v2/write/rephrase'))
    request = request.with(body: body, headers: json_headers) unless body.nil?
    request
  end

  it 'sends only the text when no other argument is given' do
    stub_rephrase(text: ['Hello']).to_return(reply(improvements: [{ text: 'Hi' }]))
    DeepL.rephrase('Hello')
  end

  it 'sends the target language, writing style and tone' do
    stub_rephrase(text: %w[a b], target_lang: 'en-GB', writing_style: 'business',
                  tone: 'diplomatic')
      .to_return(reply(improvements: [{ text: 'x' }, { text: 'y' }]))

    DeepL.rephrase(%w[a b], 'en-GB', 'business', 'diplomatic')
  end

  it 'sends the additional headers' do
    stub_request(:post, url('/v2/write/rephrase'))
      .with(headers: { 'X-DeepL-Reporting-Tag' => 'tag' })
      .to_return(reply(improvements: [{ text: 'Hi' }]))

    DeepL.rephrase('Hello', nil, nil, nil, {}, { 'X-DeepL-Reporting-Tag' => 'tag' })
  end

  it 'overrides built-in parameters with extra_body_parameters' do
    stub_rephrase(text: ['Hello'], target_lang: 'de', beta: true)
      .to_return(reply(improvements: [{ text: 'Hallo' }]))

    DeepL.rephrase('Hello', 'en', nil, nil,
                   extra_body_parameters: { target_lang: 'de', beta: true })
  end

  it 'returns a text for a string' do
    stub_rephrase.to_return(reply(improvements: [{ text: 'Hi' }]))

    expect(DeepL.rephrase('Hello')).to be_a(DeepL::Resources::Text)
  end

  it 'returns an array of texts for an array' do
    stub_rephrase.to_return(reply(improvements: [{ text: 'x' }, { text: 'y' }]))

    expect(DeepL.rephrase(%w[a b]).map(&:class)).to eq([DeepL::Resources::Text] * 2)
  end
end
