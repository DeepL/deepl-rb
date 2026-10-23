# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::SpokenTermsApi do
  let(:spoken_terms) { DeepL.spoken_terms }
  let(:collection_json) do
    { spoken_terms_id: 'st-1', name: 'terms', creation_time: '2026-10-23T17:15:53.434769Z',
      term_lists: [{ lang: 'en', entry_count: 2 }] }
  end

  describe '#create' do
    it 'sends the entries of each language joined by newlines' do
      stub_request(:post, url('/v3/spoken-terms')).with(
        body: { name: 'terms', term_lists: [{ lang: 'en', entries: "a\nb" }] },
        headers: json_headers
      ).to_return(reply(collection_json, 201))

      spoken_terms.create('terms', [DeepL::Resources::SpokenTermsEntries.new('en', %w[a b])])
    end

    it 'parses the collection, including a creation time with microseconds' do
      stub_request(:post, url('/v3/spoken-terms')).to_return(reply(collection_json, 201))

      created = spoken_terms.create('terms', [])

      expect(created.id).to eq('st-1')
      expect(created.creation_time)
        .to eq(Time.utc(2026, 10, 23, 17, 15, Rational(53_434_769, 1_000_000)))
      expect(created.term_lists.map { |l| [l.lang, l.entry_count] }).to eq([['en', 2]])
    end

    it 'accepts term lists given as hashes' do
      stub_request(:post, url('/v3/spoken-terms'))
        .with(body: { name: 'terms', term_lists: [{ lang: 'de', entries: 'x' }] })
        .to_return(reply(collection_json, 201))

      spoken_terms.create('terms', [{ lang: 'de', entries: ['x'] }])
    end
  end

  describe '#list and #find' do
    it 'parses the collections and turns a missing term_lists into an empty list' do
      stub_request(:get, url('/v3/spoken-terms'))
        .to_return(reply(spoken_terms: [collection_json.except(:term_lists)]))
      stub_request(:get, url('/v3/spoken-terms/st-1')).to_return(reply(collection_json))

      expect(spoken_terms.list.map(&:term_lists)).to eq([[]])
      expect(spoken_terms.find('st-1').name).to eq('terms')
    end
  end

  describe '#update' do
    it 'sends only the given arguments' do
      stub_request(:patch, url('/v3/spoken-terms/st-1'))
        .with(body: { term_lists: [{ lang: 'en', entries: 'c' }] }, headers: json_headers)
        .to_return(reply(collection_json))
      stub_request(:patch, url('/v3/spoken-terms/st-1')).with(body: { name: 'new' })
                                                        .to_return(reply(collection_json))

      spoken_terms.update('st-1', term_lists: [{ lang: 'en', entries: ['c'] }])
      spoken_terms.update('st-1', name: 'new')
    end

    it 'sends an empty object when no argument is given' do
      stub_request(:patch, url('/v3/spoken-terms/st-1')).with(body: '{}')
                                                        .to_return(reply(collection_json))

      spoken_terms.update('st-1')
    end
  end

  describe '#entries' do
    it 'sends the language in the query and splits the entries on newlines' do
      stub_request(:get, url('/v3/spoken-terms/st-1/entries?lang=en'))
        .with(headers: json_headers).to_return(reply(lang: 'en', entries: "a\nb\n"))

      result = spoken_terms.entries('st-1', 'en')

      expect([result.lang, result.entries]).to eq(['en', %w[a b]])
    end
  end

  describe '#replace_term_list' do
    it 'sends the entries joined by newlines and accepts a SpokenTerms object as ID' do
      stub_request(:get, url('/v3/spoken-terms/st-1')).to_return(reply(collection_json))
      stub_request(:put, url('/v3/spoken-terms/st-1/term-lists'))
        .with(body: { lang: 'en', entries: "a\nb" }, headers: json_headers)
        .to_return(reply(lang: 'en', entry_count: 2))

      list = spoken_terms.replace_term_list(spoken_terms.find('st-1'), 'en', %w[a b])

      expect([list.lang, list.entry_count]).to eq(['en', 2])
    end
  end

  describe '#destroy and #destroy_term_list' do
    it 'sends DELETE requests' do
      stub_request(:delete, url('/v3/spoken-terms/st-1/term-lists?lang=de')).to_return(status: 204)
      stub_request(:delete, url('/v3/spoken-terms/st-1')).to_return(status: 204)

      expect(spoken_terms.destroy_term_list('st-1', 'de')).to eq('de')
      expect(spoken_terms.destroy('st-1')).to eq('st-1')
    end
  end
end
