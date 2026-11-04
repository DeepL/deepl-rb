# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'stringio'
require_relative 'offline_helper'

describe 'DeepL::Client v2 glossaries' do
  let(:glossary_json) do
    { glossary_id: 'g-1', name: 'terms', ready: true, source_lang: 'en', target_lang: 'de',
      creation_time: '2026-01-02T03:04:05.678Z', entry_count: 2 }
  end
  let(:glossary) { DeepL::Resources::Glossary.new(glossary_json.transform_keys(&:to_s), nil, nil) }

  describe '#create_glossary' do
    it 'sends the entries as TSV with the base languages and returns the glossary' do
      stub_request(:post, url('/v2/glossaries')).with(
        body: { name: 'terms', source_lang: 'EN', target_lang: 'DE',
                entries: "Apple\tApfel\nBanana\tBanane", entries_format: 'tsv' },
        headers: json_headers
      ).to_return(reply(glossary_json, 201))

      created = api_client.create_glossary('terms', 'en-GB', 'DE',
                                           { ' Apple ' => 'Apfel', 'Banana' => 'Banane' })

      expect([created.class, created.id, created.entry_count])
        .to eq([DeepL::Resources::Glossary, 'g-1', 2])
    end

    it 'raises ArgumentError for an empty name or no entries without sending a request' do
      expect { api_client.create_glossary('', 'EN', 'DE', { 'a' => 'b' }) }
        .to raise_error(ArgumentError, /name/)
      expect { api_client.create_glossary('terms', 'EN', 'DE', {}) }
        .to raise_error(ArgumentError, /entries/)
    end

    it 'raises an ArgumentError for an invalid term without sending a request' do
      expect { api_client.create_glossary('g', 'EN', 'DE', { ' ' => 'x' }) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#create_glossary_from_csv' do
    it 'sends CSV content read from an IO as given' do
      stub_request(:post, url('/v2/glossaries')).with(
        body: { name: 'terms', source_lang: 'EN', target_lang: 'DE', entries: "Apple,Apfel\n",
                entries_format: 'csv' }
      ).to_return(reply(glossary_json, 201))

      created = api_client.create_glossary_from_csv('terms', 'EN', 'DE',
                                                    StringIO.new("Apple,Apfel\n"))

      expect(created.name).to eq('terms')
    end
  end

  describe '#list_glossaries' do
    it 'sends a GET without a body and returns one glossary per entry' do
      stub_request(:get, url('/v2/glossaries')).with(headers: auth_headers) { bodyless?(_1) }
                                               .to_return(reply(glossaries: [glossary_json]))

      expect(api_client.list_glossaries.map(&:id)).to eq(['g-1'])
    end
  end

  describe '#get_glossary' do
    it 'sends a GET with the URL-encoded ID of an ID or a glossary' do
      stub_request(:get, url('/v2/glossaries/a%2Fb%20c'))
        .with(headers: auth_headers) { |request| bodyless?(request) }
        .to_return(reply(glossary_json))
      stub_request(:get, url('/v2/glossaries/g-1')).to_return(reply(glossary_json))

      expect(api_client.get_glossary('a/b c').name).to eq('terms')
      expect(api_client.get_glossary(glossary).id).to eq('g-1')
    end
  end

  describe '#get_glossary_entries' do
    it 'requests TSV and returns the entries as a hash' do
      stub_request(:get, url('/v2/glossaries/g-1/entries'))
        .with(headers: auth_headers.merge('Accept' => 'text/tab-separated-values')) do |request|
          bodyless?(request)
        end
        .to_return(status: 200, body: "Apple\tApfel\nBanana\tBanane\n")

      expect(api_client.get_glossary_entries(glossary))
        .to eq('Apple' => 'Apfel', 'Banana' => 'Banane')
    end
  end

  describe '#delete_glossary' do
    it 'sends a DELETE without a body and returns nil' do
      stub_request(:delete, url('/v2/glossaries/g-1')).with(headers: auth_headers) { bodyless?(_1) }
                                                      .to_return(status: 204)

      expect(api_client.delete_glossary(glossary)).to be_nil
    end
  end

  describe '#get_glossary_languages' do
    it 'pairs every glossary source language with every other target language' do
      stub_request(:get, url('/v3/languages?resource=glossary')).to_return(
        reply([{ lang: 'en', usable_as_source: true, usable_as_target: true },
               { lang: 'de', usable_as_source: true, usable_as_target: true },
               { lang: 'fr', usable_as_source: false, usable_as_target: true }])
      )

      pairs = api_client.get_glossary_languages

      expect(pairs).to all(be_a(DeepL::Resources::LanguagePair))
      expect(pairs.map(&:to_s)).to eq(['en - de', 'en - fr', 'de - en', 'de - fr'])
    end
  end
end
