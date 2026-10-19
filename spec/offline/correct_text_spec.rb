# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL.correct' do
  def stub_correct(body = nil)
    request = stub_request(:post, url('/v2/write/correct'))
    request = request.with(body: body, headers: json_headers) unless body.nil?
    request
  end

  it 'sends only the text when no target language is given' do
    stub_correct(text: ['Helo']).to_return(reply(improvements: [{ text: 'Hello' }]))
    DeepL.correct('Helo')
  end

  it 'sends the target language and several texts' do
    stub_correct(text: %w[a b], target_lang: 'en-US')
      .to_return(reply(improvements: [{ text: 'a' }, { text: 'b' }]))

    DeepL.correct(%w[a b], 'en-US')
  end

  it 'sends the additional headers and the extra body parameters' do
    stub_request(:post, url('/v2/write/correct'))
      .with(body: { text: ['a'], beta: 1 }, headers: { 'X-DeepL-Reporting-Tag' => 'tag' })
      .to_return(reply(improvements: [{ text: 'a' }]))

    DeepL.correct('a', nil, { extra_body_parameters: { beta: 1 } },
                  { 'X-DeepL-Reporting-Tag' => 'tag' })
  end

  it 'parses a string into a text' do
    stub_correct.to_return(reply(improvements: [{ text: 'Hello', detected_source_language: 'EN' }]))

    result = DeepL.correct('Helo')

    expect([result.text, result.detected_source_language]).to eq(%w[Hello EN])
  end

  it 'parses an array into an array of texts, even for a single element' do
    stub_correct.to_return(reply(improvements: [{ text: 'Hello' }]))

    expect(DeepL.correct(['Helo']).map(&:text)).to eq(['Hello'])
  end

  [[''], [[]], [['a', '']]].each do |args|
    it "raises ArgumentError for #{args.first.inspect} without sending a request" do
      expect { DeepL.correct(*args) }.to raise_error(ArgumentError, /non-empty/)
    end
  end
end
