# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL::Client#correct_text' do
  let(:client) { DeepL::Client.new(OfflineHelper::AUTH_KEY) }

  def stub_correct(body = nil)
    request = stub_request(:post, url('/v2/write/correct'))
    request = request.with(body: body, headers: json_headers) unless body.nil?
    request
  end

  it 'sends only the text when no target language is given' do
    stub_correct(text: ['Helo']).to_return(reply(improvements: [{ text: 'Hello' }]))
    client.correct_text('Helo')
  end

  it 'sends several texts' do
    stub_correct(text: %w[a b], target_lang: 'en-US')
      .to_return(reply(improvements: [{ text: 'a' }, { text: 'b' }]))

    client.correct_text(%w[a b], 'en-US')
  end

  it 'returns a text for a string' do
    stub_correct.to_return(reply(improvements: [{ text: 'Hello' }]))

    expect(client.correct_text('Helo')).to be_a(DeepL::Resources::Text)
  end

  [['Helo', []], [%w[a b], [{ text: 'x' }]]].each do |text, improvements|
    it "raises DeepL::Exceptions::Error for #{improvements.size} improvements of #{text.inspect}" do
      stub_correct.to_return(reply(improvements: improvements))

      expect { client.correct_text(text) }
        .to raise_error(an_instance_of(DeepL::Exceptions::Error), /expected \d improvements/)
    end
  end

  [[''], [[]], [['a', '']]].each do |args|
    it "raises ArgumentError for #{args.first.inspect} without sending a request" do
      expect { client.correct_text(*args) }.to raise_error(ArgumentError, /non-empty/)
      expect(a_request(:any, /.*/)).not_to have_been_made
    end
  end
end
