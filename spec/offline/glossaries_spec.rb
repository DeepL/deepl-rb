# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::GlossaryApi do
  let(:glossaries) { DeepL.glossaries }
  let(:glossary_json) do
    { glossary_id: 'g-1', name: 'terms', ready: true, source_lang: 'en', target_lang: 'de',
      creation_time: '2026-01-02T03:04:05.678Z', entry_count: 2 }
  end

  describe '#create' do
    it 'sends the entries of an array as TSV' do
      stub_request(:post, url('/v2/glossaries')).with(
        body: { name: 'terms', source_lang: 'EN', target_lang: 'DE',
                entries: "Apple\tApfel\nBanana\tBanane\n", entries_format: 'tsv' },
        headers: json_headers
      ).to_return(reply(glossary_json, 201))

      glossaries.create('terms', 'EN', 'DE', [%w[Apple Apfel], %w[Banana Banane]])
    end

    it 'sends a string of entries and the entries format as given' do
      stub_request(:post, url('/v2/glossaries')).with(
        body: { name: 'terms', source_lang: 'EN', target_lang: 'DE', entries: "Apple,Apfel\n",
                entries_format: 'csv' }
      ).to_return(reply(glossary_json, 201))

      glossaries.create('terms', 'EN', 'DE', "Apple,Apfel\n", entries_format: 'csv')
    end

    it 'strips surrounding whitespace from the terms of an array' do
      stub_request(:post, url('/v2/glossaries'))
        .with(body: hash_including(entries: "Apple\tApfel\n"))
        .to_return(reply(glossary_json, 201))

      glossaries.create('terms', 'EN', 'DE', [[' Apple ', "Apfel\n"]])
    end

    it 'returns a glossary' do
      stub_request(:post, url('/v2/glossaries')).to_return(reply(glossary_json, 201))

      expect(glossaries.create('terms', 'EN', 'DE', [%w[a b]])).to be_a(DeepL::Resources::Glossary)
    end
  end

  describe '#create with invalid terms' do
    [[%W[Apple\tPie Apfel]], [%W[Apple Apfel\nKuchen]], [['Apple', ' ']]].each do |entries|
      it "raises ValidationError for #{entries.inspect} and sends no request" do
        expect { glossaries.create('terms', 'EN', 'DE', entries) }
          .to raise_error(DeepL::Exceptions::ValidationError)
        expect(a_request(:any, /.*/)).not_to have_been_made
      end
    end
  end

  describe '#find' do
    it 'sends a GET without a body' do
      stub_request(:get, url('/v2/glossaries/g-1')).with(headers: auth_headers) { bodyless?(_1) }
                                                   .to_return(reply(glossary_json))

      glossaries.find('g-1')
    end
  end

  describe '#list' do
    it 'returns one glossary per entry of the reply' do
      second = glossary_json.merge(glossary_id: 'g-2')
      stub_request(:get, url('/v2/glossaries'))
        .with(headers: auth_headers) { bodyless?(_1) }
        .to_return(reply(glossaries: [glossary_json, second]))

      expect(glossaries.list.size).to eq(2)
    end
  end

  describe '#entries' do
    it 'parses the TSV reply into pairs' do
      stub_request(:get, url('/v2/glossaries/g-1/entries'))
        .with(headers: auth_headers) { bodyless?(_1) }
        .to_return(status: 200, body: "Apple\tApfel\nBanana\tBanane")

      expect(glossaries.entries('g-1')).to eq([%w[Apple Apfel], %w[Banana Banane]])
    end
  end

  describe '#destroy' do
    it 'sends a DELETE without a body and returns the ID' do
      stub_request(:delete, url('/v2/glossaries/g-1')).with(headers: auth_headers) { bodyless?(_1) }
                                                      .to_return(status: 204)

      expect(glossaries.destroy('g-1')).to eq('g-1')
    end
  end
end
