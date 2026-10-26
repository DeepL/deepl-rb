# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::MultilingualGlossaryApi do
  let(:glossaries) { DeepL.multilingual_glossaries }
  let(:glossary_json) do
    { glossary_id: 'g-1', name: 'terms', creation_time: '2026-01-02T03:04:05.678Z',
      dictionaries: [{ source_lang: 'en', target_lang: 'de', entry_count: 2 }] }
  end
  let(:dictionary_json) { { source_lang: 'en', target_lang: 'de', entry_count: 2 } }

  describe '#create' do
    it 'sends the entries of each dictionary as TSV' do
      stub_request(:post, url('/v3/glossaries')).with(
        body: { name: 'terms',
                dictionaries: [{ source_lang: 'EN', target_lang: 'DE',
                                 entries: "Apple\tApfel\nBanana\tBanane",
                                 entries_format: 'tsv' }] },
        headers: json_headers
      ).to_return(reply(glossary_json, 201))

      glossaries.create('terms', [{ source_lang: 'EN', target_lang: 'DE',
                                    entries: [%w[Apple Apfel], %w[Banana Banane]] }])
    end

    it 'accepts dictionaries with string keys and a string of entries' do
      stub_request(:post, url('/v3/glossaries')).with(
        body: { name: 'terms',
                dictionaries: [{ source_lang: 'EN', target_lang: 'FR', entries: "a\tb",
                                 entries_format: 'tsv' }] }
      ).to_return(reply(glossary_json, 201))

      glossaries.create('terms', [{ 'source_lang' => 'EN', 'target_lang' => 'FR',
                                    'entries' => "a\tb" }])
    end

    it 'parses the dictionaries of the glossary' do
      stub_request(:post, url('/v3/glossaries')).to_return(reply(glossary_json, 201))

      expect(glossaries.create('terms', []).dictionaries.map(&:class))
        .to eq([DeepL::Resources::MultilingualGlossaryDictionary])
    end
  end

  describe '#create with invalid terms' do
    [[%W[Apple\tPie Apfel]], [%W[Apple Apfel\nKuchen]]].each do |entries|
      it "raises ArgumentError for #{entries.inspect} and sends no request" do
        dictionaries = [{ source_lang: 'EN', target_lang: 'DE', entries: entries }]

        expect { glossaries.create('terms', dictionaries) }.to raise_error(ArgumentError)
        expect(a_request(:any, /.*/)).not_to have_been_made
      end
    end
  end

  describe '#create_with_csv' do
    it 'sends the CSV content with the csv entries format' do
      stub_request(:post, url('/v3/glossaries')).with(
        body: { name: 'terms',
                dictionaries: [{ source_lang: 'EN', target_lang: 'DE', entries: "a,b\n",
                                 entries_format: 'csv' }] }
      ).to_return(reply(glossary_json, 201))

      glossaries.create_with_csv('terms', 'EN', 'DE', "a,b\n")
    end
  end

  describe '#find and #list' do
    it 'sends GET requests with an empty JSON body' do
      stub_request(:get, url('/v3/glossaries/g-1')).with(body: '{}', headers: json_headers)
                                                   .to_return(reply(glossary_json))
      stub_request(:get, url('/v3/glossaries')).with(body: '{}', headers: json_headers)
                                               .to_return(reply(glossaries: [glossary_json]))

      glossaries.find('g-1')
      glossaries.list
    end
  end

  describe '#entries' do
    it 'sends the language pair in the query' do
      stub_request(:get, url('/v3/glossaries/g-1/entries?source_lang=EN&target_lang=DE'))
        .with(headers: json_headers)
        .to_return(reply(dictionaries: [{ source_lang: 'en', target_lang: 'de',
                                          entries: "a\tb", entries_format: 'tsv' }]))

      glossaries.entries('g-1', 'EN', 'DE')
    end
  end

  describe '#update_name' do
    it 'sends a PATCH with the name' do
      stub_request(:patch, url('/v3/glossaries/g-1')).with(body: { name: 'new' },
                                                           headers: json_headers)
                                                     .to_return(reply(glossary_json))

      glossaries.update_name('g-1', 'new')
    end
  end

  describe '#update_dictionary' do
    it 'sends a PATCH with the dictionary entries as TSV' do
      stub_request(:patch, url('/v3/glossaries/g-1')).with(
        body: { dictionaries: [{ source_lang: 'EN', target_lang: 'DE', entries: "a\tb",
                                 entries_format: 'tsv' }] }
      ).to_return(reply(glossary_json))

      glossaries.update_dictionary('g-1', 'EN', 'DE', [%w[a b]])
    end

    it 'sends the CSV content with the csv entries format' do
      stub_request(:patch, url('/v3/glossaries/g-1')).with(
        body: { dictionaries: [{ source_lang: 'EN', target_lang: 'DE', entries: "a,b\n",
                                 entries_format: 'csv' }] }
      ).to_return(reply(glossary_json))

      glossaries.update_dictionary_with_csv('g-1', 'EN', 'DE', "a,b\n")
    end
  end

  describe '#replace_dictionary' do
    it 'sends a PUT with the entries as TSV' do
      stub_request(:put, url('/v3/glossaries/g-1/dictionaries')).with(
        body: { source_lang: 'EN', target_lang: 'DE', entries: "a\tb", entries_format: 'tsv' },
        headers: json_headers
      ).to_return(reply(dictionary_json))

      glossaries.replace_dictionary('g-1', 'EN', 'DE', [%w[a b]])
    end

    it 'sends the CSV content with the csv entries format' do
      stub_request(:put, url('/v3/glossaries/g-1/dictionaries')).with(
        body: { source_lang: 'EN', target_lang: 'DE', entries: "a,b\n", entries_format: 'csv' }
      ).to_return(reply(dictionary_json))

      glossaries.replace_dictionary_with_csv('g-1', 'EN', 'DE', "a,b\n")
    end
  end

  describe '#destroy_dictionary' do
    it 'sends a DELETE with the language pair in the query and no body' do
      stub_request(:delete, url('/v3/glossaries/g-1/dictionaries?source_lang=EN&target_lang=DE'))
        .with(body: nil, headers: json_headers).to_return(status: 204)

      expect(glossaries.destroy_dictionary('g-1', 'EN', 'DE'))
        .to eq({ source_lang: 'EN', target_lang: 'DE' })
    end
  end

  describe '#destroy' do
    it 'sends a DELETE with an empty JSON body and returns the ID' do
      stub_request(:delete, url('/v3/glossaries/g-1')).with(body: '{}', headers: json_headers)
                                                      .to_return(status: 204)

      expect(glossaries.destroy('g-1')).to eq('g-1')
    end
  end
end
