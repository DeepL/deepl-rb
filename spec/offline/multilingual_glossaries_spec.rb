# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'multilingual glossaries' do
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

      it 'trims the terms of a TSV string of entries and skips blank lines' do
        stub_request(:post, url('/v3/glossaries')).with(
          body: { name: 'terms',
                  dictionaries: [{ source_lang: 'EN', target_lang: 'DE',
                                   entries: "Apple\tApfel\nBanana\tBanane",
                                   entries_format: 'tsv' }] }
        ).to_return(reply(glossary_json, 201))

        glossaries.create('terms', [{ source_lang: 'EN', target_lang: 'DE',
                                      entries: " Apple \t Apfel\r\n\n  Banana\tBanane \n" }])
      end

      it 'parses the dictionaries of the glossary' do
        stub_request(:post, url('/v3/glossaries')).to_return(reply(glossary_json, 201))

        expect(glossaries.create('terms', []).dictionaries.map(&:class))
          .to eq([DeepL::Resources::MultilingualGlossaryDictionary])
      end
    end

    describe '#create with invalid terms' do
      [[%W[Apple\tPie Apfel]], [%W[Apple Apfel\nKuchen]], "Apple\tApfel\tKuchen", "Apple\n",
       " \tApfel", "Apple\tAp\u0001fel", "Apple\tAp\u2028fel"].each do |entries|
        it "raises ValidationError for #{entries.inspect} and sends no request" do
          dictionaries = [{ source_lang: 'EN', target_lang: 'DE', entries: entries }]

          expect { glossaries.create('terms', dictionaries) }
            .to raise_error(DeepL::Exceptions::ValidationError)
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
      it 'sends GET requests without a body' do
        stub_request(:get, url('/v3/glossaries/g-1')).with(headers: auth_headers) { bodyless?(_1) }
                                                     .to_return(reply(glossary_json))
        stub_request(:get, url('/v3/glossaries')).with(headers: auth_headers) { bodyless?(_1) }
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

        expect(glossaries.destroy_dictionary('g-1', 'EN', 'DE')).to be_nil
      end
    end

    describe '#destroy' do
      it 'sends a DELETE without a body and returns nil' do
        stub_request(:delete, url('/v3/glossaries/g-1'))
          .with(headers: auth_headers) { bodyless?(_1) }
          .to_return(status: 204)

        expect(glossaries.destroy('g-1')).to be_nil
      end
    end
  end

  # The client has its own key and server, different from the module configuration, so a request
  # that falls back to module state hits no stub.
  describe 'DeepL::Client' do
    let(:client) { DeepL::Client.new('client-key', server_url: 'https://client.example.test') }
    let(:glossary_json) do
      { glossary_id: 'g-1', name: 'terms', creation_time: '2026-10-23T17:15:53.434769Z',
        dictionaries: [{ source_lang: 'en', target_lang: 'de', entry_count: 2 }] }
    end
    let(:dictionary_json) { { source_lang: 'en', target_lang: 'de', entry_count: 1 } }
    let(:apple) do
      DeepL::Resources::MultilingualGlossaryDictionaryEntries.new('EN', 'DE', [%w[Apple Apfel]])
    end

    def url(path)
      "https://client.example.test#{path}"
    end

    def json_headers
      { 'Authorization' => 'DeepL-Auth-Key client-key', 'Content-Type' => 'application/json' }
    end

    def auth_headers
      { 'Authorization' => 'DeepL-Auth-Key client-key' }
    end

    def no_body
      ->(body) { body.to_s.empty? }
    end

    def glossary
      stub_request(:get, url('/v3/glossaries/g-1')).to_return(reply(glossary_json))
      client.get_multilingual_glossary('g-1')
    end

    describe '#create_multilingual_glossary' do
      it 'takes MultilingualGlossaryDictionaryEntries objects and sends them as TSV' do
        stub_request(:post, url('/v3/glossaries')).with(
          body: { name: 'terms', dictionaries: [{ source_lang: 'EN', target_lang: 'DE',
                                                  entries: "Apple\tApfel", entries_format: 'tsv' }],
                  beta: true },
          headers: json_headers
        ).to_return(reply(glossary_json, 201))

        client.create_multilingual_glossary('terms', [apple], extra_body_parameters: { beta: true })
      end

      it 'trims the terms of MultilingualGlossaryDictionaryEntries given as a TSV string' do
        dictionary = { source_lang: 'EN', target_lang: 'DE', entries: "Apple\tApfel",
                       entries_format: 'tsv' }
        stub_request(:post, url('/v3/glossaries'))
          .with(body: { name: 'terms', dictionaries: [dictionary] })
          .to_return(reply(glossary_json, 201))
        entries_class = DeepL::Resources::MultilingualGlossaryDictionaryEntries
        entries = entries_class.new('EN', 'DE', "Apple \tApfel\n")

        client.create_multilingual_glossary('terms', [entries])
      end

      it 'parses the creation time as a UTC Time' do
        stub_request(:post, url('/v3/glossaries')).to_return(reply(glossary_json, 201))

        created = client.create_multilingual_glossary('terms', [])

        expect(created.creation_time)
          .to eq(Time.utc(2026, 10, 23, 17, 15, Rational(53_434_769, 1_000_000)))
      end
    end

    describe '#create_multilingual_glossary_from_csv' do
      it 'sends the CSV content of a string or an IO with the csv entries format' do
        body = { name: 'terms', dictionaries: [{ source_lang: 'EN', target_lang: 'DE',
                                                 entries: "a,b\n", entries_format: 'csv' }] }
        stub_request(:post, url('/v3/glossaries')).with(body: body)
                                                  .to_return(reply(glossary_json, 201))

        client.create_multilingual_glossary_from_csv('terms', 'EN', 'DE', "a,b\n")
        client.create_multilingual_glossary_from_csv('terms', 'EN', 'DE', StringIO.new("a,b\n"))
      end
    end

    describe '#list_multilingual_glossaries and #get_multilingual_glossary' do
      it 'send GET requests and take a glossary object' do
        stub_request(:get, url('/v3/glossaries')).with(headers: auth_headers)
                                                 .to_return(reply(glossaries: [glossary_json]))

        expect(client.list_multilingual_glossaries.map(&:id)).to eq(['g-1'])
        expect(client.get_multilingual_glossary(glossary).name).to eq('terms')
      end
    end

    describe '#update_multilingual_glossary' do
      it 'sends the name and the dictionaries' do
        stub_request(:patch, url('/v3/glossaries/g-1')).with(
          body: { name: 'new', dictionaries: [{ source_lang: 'EN', target_lang: 'FR',
                                                entries: "a\tb", entries_format: 'tsv' }] },
          headers: json_headers
        ).to_return(reply(glossary_json))

        client.update_multilingual_glossary(
          'g-1', name: 'new', dictionaries: [{ source_lang: 'EN', target_lang: 'FR',
                                               entries: [%w[a b]] }]
        )
      end

      it 'sends an empty object when no argument is given' do
        stub_request(:patch, url('/v3/glossaries/g-1')).with(body: '{}')
                                                       .to_return(reply(glossary_json))

        client.update_multilingual_glossary('g-1')
      end
    end

    describe '#update_multilingual_glossary_name and #update_multilingual_glossary_dictionary' do
      it 'send a PATCH with only the name or only the dictionary' do
        stub_request(:patch, url('/v3/glossaries/g-1')).with(body: { name: 'new' })
                                                       .to_return(reply(glossary_json))
        stub_request(:patch, url('/v3/glossaries/g-1')).with(
          body: { dictionaries: [{ source_lang: 'EN', target_lang: 'DE', entries: "Apple\tApfel",
                                   entries_format: 'tsv' }] }
        ).to_return(reply(glossary_json))

        client.update_multilingual_glossary_name(glossary, 'new')
        client.update_multilingual_glossary_dictionary(glossary, apple)
      end

      it 'sends CSV content with the csv entries format' do
        stub_request(:patch, url('/v3/glossaries/g-1')).with(
          body: { dictionaries: [{ source_lang: 'EN', target_lang: 'DE', entries: "a,b\n",
                                   entries_format: 'csv' }] }
        ).to_return(reply(glossary_json))

        client.update_multilingual_glossary_dictionary_from_csv('g-1', 'EN', 'DE', "a,b\n")
      end
    end

    describe '#replace_multilingual_glossary_dictionary' do
      it 'sends a PUT with one dictionary given as a hash' do
        stub_request(:put, url('/v3/glossaries/g-1/dictionaries')).with(
          body: { source_lang: 'EN', target_lang: 'DE', entries: "a\tb", entries_format: 'tsv' },
          headers: json_headers
        ).to_return(reply(dictionary_json))

        replaced = client.replace_multilingual_glossary_dictionary(
          'g-1', { source_lang: 'EN', target_lang: 'DE', entries: [%w[a b]] }
        )

        expect([replaced.source_lang, replaced.target_lang, replaced.entry_count])
          .to eq(['en', 'de', 1])
      end

      it 'sends CSV content with the csv entries format' do
        stub_request(:put, url('/v3/glossaries/g-1/dictionaries')).with(
          body: { source_lang: 'EN', target_lang: 'DE', entries: "a,b\n", entries_format: 'csv' }
        ).to_return(reply(dictionary_json))

        client.replace_multilingual_glossary_dictionary_from_csv('g-1', 'EN', 'DE', "a,b\n")
      end
    end

    describe '#get_multilingual_glossary_dictionary_entries' do
      it 'encodes a space in a query value as %20' do
        expect(Net::HTTP::Get).to receive(:new)
          .with('/v3/glossaries/g-1/entries?source_lang=E%20N&target_lang=DE', anything)
          .and_call_original
        stub_request(:get, url('/v3/glossaries/g-1/entries?source_lang=E%20N&target_lang=DE'))
          .to_return(reply(dictionaries: [{ source_lang: 'en', target_lang: 'de', entries: '',
                                            entries_format: 'tsv' }]))

        client.get_multilingual_glossary_dictionary_entries('g-1', 'E N', 'DE')
      end

      it 'returns the one dictionary with its entries as source/target pairs' do
        stub_request(:get, url('/v3/glossaries/g-1/entries?source_lang=EN&target_lang=DE'))
          .with(headers: json_headers)
          .to_return(reply(dictionaries: [{ source_lang: 'en', target_lang: 'de',
                                            entries: "Apple\tApfel\nBanana\tBanane\n",
                                            entries_format: 'tsv' }]))

        result = client.get_multilingual_glossary_dictionary_entries('g-1', 'EN', 'DE')

        expect([result.source_lang, result.target_lang, result.entries])
          .to eq(['en', 'de', [%w[Apple Apfel], %w[Banana Banane]]])
      end

      it 'raises NotFound when the glossary has no dictionary for the language pair' do
        stub_request(:get, url('/v3/glossaries/g-1/entries?source_lang=EN&target_lang=JA'))
          .to_return(reply(dictionaries: []))

        expect { client.get_multilingual_glossary_dictionary_entries('g-1', 'EN', 'JA') }
          .to raise_error(DeepL::Exceptions::NotFound, /no dictionary for EN -> JA/)
      end

      it 'returns entries that can be sent to another glossary' do
        stub_request(:get, url('/v3/glossaries/g-1/entries?source_lang=EN&target_lang=DE'))
          .to_return(reply(dictionaries: [{ source_lang: 'en', target_lang: 'de',
                                            entries: "a\tb", entries_format: 'tsv' }]))
        stub_request(:post, url('/v3/glossaries')).with(
          body: { name: 'copy', dictionaries: [{ source_lang: 'en', target_lang: 'de',
                                                 entries: "a\tb", entries_format: 'tsv' }] }
        ).to_return(reply(glossary_json, 201))

        entries = client.get_multilingual_glossary_dictionary_entries('g-1', 'EN', 'DE')
        client.create_multilingual_glossary('copy', [entries])
      end
    end

    describe '#delete_multilingual_glossary_dictionary and #delete_multilingual_glossary' do
      it 'send DELETE requests and return nil' do
        stub_request(:delete, url('/v3/glossaries/g-1/dictionaries?source_lang=EN&target_lang=FR'))
          .with(headers: json_headers, body: no_body).to_return(status: 204)
        stub_request(:delete, url('/v3/glossaries/g-1')).with(headers: auth_headers)
                                                        .to_return(status: 204)

        expect(client.delete_multilingual_glossary_dictionary(glossary, 'EN', 'FR')).to be_nil
        expect(client.delete_multilingual_glossary(glossary)).to be_nil
      end
    end

    describe 'glossary IDs' do
      before do
        encoded = url('/v3/glossaries/a%20b%2Fc')
        stub_request(:get, encoded).to_return(reply(glossary_json))
        stub_request(:patch, encoded).to_return(reply(glossary_json))
        stub_request(:delete, encoded).to_return(status: 204)
        stub_request(:get, "#{encoded}/entries?source_lang=EN&target_lang=DE")
          .to_return(reply(dictionaries: [{ source_lang: 'en', target_lang: 'de', entries: '' }]))
        stub_request(:put, "#{encoded}/dictionaries").to_return(reply(dictionary_json))
        stub_request(:delete, "#{encoded}/dictionaries?source_lang=EN&target_lang=DE")
          .to_return(status: 204)
      end

      it 'are URL-encoded in every path' do
        id = 'a b/c'
        client.get_multilingual_glossary(id)
        client.update_multilingual_glossary_name(id, 'x')
        client.delete_multilingual_glossary(id)
        client.get_multilingual_glossary_dictionary_entries(id, 'EN', 'DE')
        client.replace_multilingual_glossary_dictionary(id, apple)
        client.delete_multilingual_glossary_dictionary(id, 'EN', 'DE')
      end
    end
  end
end
