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

  it 'returns a text for a string' do
    stub_correct.to_return(reply(improvements: [{ text: 'Hello' }]))

    expect(DeepL.correct('Helo')).to be_a(DeepL::Resources::Text)
  end

  it 'parses the target language of each improvement' do
    stub_correct.to_return(reply(improvements: [{ text: 'Hello', target_language: 'en-US' }]))

    expect(DeepL.correct('Helo').target_language).to eq('en-US')
  end

  it 'returns an array of texts for an array, even for a single element' do
    stub_correct.to_return(reply(improvements: [{ text: 'Hello' }]))

    expect(DeepL.correct(['Helo']).map(&:class)).to eq([DeepL::Resources::Text])
  end

  [['Helo', []], [%w[a b], [{ text: 'x' }]]].each do |text, improvements|
    it "raises DeepL::Exceptions::Error for #{improvements.size} improvements of #{text.inspect}" do
      stub_correct.to_return(reply(improvements: improvements))

      expect { DeepL.correct(text) }
        .to raise_error(an_instance_of(DeepL::Exceptions::Error), /expected \d improvements/)
    end
  end

  [[''], [[]], [['a', '']]].each do |args|
    it "raises ArgumentError for #{args.first.inspect} without sending a request" do
      expect { DeepL.correct(*args) }.to raise_error(ArgumentError, /non-empty/)
    end
  end
end
