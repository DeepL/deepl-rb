# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

# The client has its own key and server, different from the module configuration, so a request
# that falls back to module state hits no stub.
describe 'DeepL::Client spoken terms' do
  let(:client) { DeepL::Client.new('client-key', server_url: 'https://client.example.test') }
  let(:collection_json) do
    { spoken_terms_id: 'st-1', name: 'terms', creation_time: '2026-10-23T17:15:53.434769Z',
      term_lists: [{ lang: 'en', entry_count: 2 }] }
  end

  def url(path)
    "https://client.example.test#{path}"
  end

  def json_headers
    { 'Authorization' => 'DeepL-Auth-Key client-key', 'Content-Type' => 'application/json' }
  end

  def no_body
    ->(body) { body.to_s.empty? }
  end

  def collection(json = collection_json)
    stub_request(:get, url('/v3/spoken-terms/st-1')).to_return(reply(json))
    client.get_spoken_terms('st-1')
  end

  describe '#create_spoken_terms' do
    it 'sends the entries of each language joined by newlines' do
      stub_request(:post, url('/v3/spoken-terms')).with(
        body: { name: 'terms', term_lists: [{ lang: 'en', entries: "a\nb" }] },
        headers: json_headers
      ).to_return(reply(collection_json, 201))

      client.create_spoken_terms('terms', [DeepL::Resources::SpokenTermsEntries.new('en', %w[a b])])
    end

    it 'accepts term lists given as hashes and sends the extra body parameters' do
      stub_request(:post, url('/v3/spoken-terms'))
        .with(body: { name: 'terms', term_lists: [{ lang: 'de', entries: 'x' }], beta: true })
        .to_return(reply(collection_json, 201))

      client.create_spoken_terms('terms', [{ lang: 'de', entries: ['x'] }],
                                 extra_body_parameters: { beta: true })
    end

    it 'parses the collection, including a creation time with microseconds' do
      stub_request(:post, url('/v3/spoken-terms')).to_return(reply(collection_json, 201))

      created = client.create_spoken_terms('terms', [])

      expect(created.spoken_terms_id).to eq('st-1')
      expect(created.creation_time)
        .to eq(Time.utc(2026, 10, 23, 17, 15, Rational(53_434_769, 1_000_000)))
      expect(created.term_lists.map { |l| [l.lang, l.entry_count] }).to eq([['en', 2]])
    end
  end

  describe 'SpokenTerms#creation_time' do
    it 'is nil for a malformed timestamp' do
      expect(collection(collection_json.merge(creation_time: 'yesterday')).creation_time).to be_nil
    end

    it 'reads a timestamp without an offset as UTC, not local time' do
      original_tz = ENV.fetch('TZ', nil)
      ENV['TZ'] = 'America/New_York'
      expect(collection(collection_json.merge(creation_time: '2026-10-23T17:15:53')).creation_time)
        .to eq(Time.utc(2026, 10, 23, 17, 15, 53))
    ensure
      ENV['TZ'] = original_tz
    end
  end

  describe 'term check' do
    it 'strips surrounding whitespace from each term before sending it' do
      stub_request(:post, url('/v3/spoken-terms'))
        .with(body: { name: 'terms', term_lists: [{ lang: 'en', entries: "API\nDeepL" }] })
        .to_return(reply(collection_json, 201))

      client.create_spoken_terms('terms', [{ lang: 'en', entries: [' API ', "DeepL\n"] }])
    end

    [["a\nb"], ['  ']].each do |bad|
      it "raises ArgumentError for #{bad.inspect} and sends no request" do
        expect { client.create_spoken_terms('terms', [{ lang: 'en', entries: bad }]) }
          .to raise_error(ArgumentError)
        expect { client.update_spoken_terms('st-1', term_lists: [{ lang: 'en', entries: bad }]) }
          .to raise_error(ArgumentError)
        expect { client.replace_spoken_terms_list('st-1', { lang: 'en', entries: bad }) }
          .to raise_error(ArgumentError)
        expect(a_request(:any, /.*/)).not_to have_been_made
      end
    end
  end

  describe '#list_spoken_terms and #get_spoken_terms' do
    it 'send GET requests without a body' do
      stub_request(:get, url('/v3/spoken-terms')).with(headers: json_headers, body: no_body)
                                                 .to_return(reply(spoken_terms: [collection_json]))
      stub_request(:get, url('/v3/spoken-terms/st-1')).with(headers: json_headers, body: no_body)
                                                      .to_return(reply(collection_json))

      expect(client.list_spoken_terms.map(&:spoken_terms_id)).to eq(['st-1'])
      expect(client.get_spoken_terms('st-1').name).to eq('terms')
    end

    it 'turns a missing term_lists into an empty list' do
      stub_request(:get, url('/v3/spoken-terms'))
        .to_return(reply(spoken_terms: [collection_json.reject { |k, _| k == :term_lists }]))

      expect(client.list_spoken_terms.map(&:term_lists)).to eq([[]])
    end
  end

  describe '#update_spoken_terms' do
    it 'sends only the given arguments' do
      stub_request(:patch, url('/v3/spoken-terms/st-1'))
        .with(body: { term_lists: [{ lang: 'en', entries: 'c' }] }, headers: json_headers)
        .to_return(reply(collection_json))
      stub_request(:patch, url('/v3/spoken-terms/st-1')).with(body: { name: 'new' })
                                                        .to_return(reply(collection_json))

      client.update_spoken_terms('st-1', term_lists: [{ lang: 'en', entries: ['c'] }])
      client.update_spoken_terms('st-1', name: 'new')
    end

    it 'sends the extra body parameters' do
      stub_request(:patch, url('/v3/spoken-terms/st-1'))
        .with(body: { name: 'new', beta: true }).to_return(reply(collection_json))

      client.update_spoken_terms('st-1', name: 'new', extra_body_parameters: { beta: true })
    end

    it 'sends an empty object when no argument is given' do
      stub_request(:patch, url('/v3/spoken-terms/st-1')).with(body: '{}')
                                                        .to_return(reply(collection_json))

      client.update_spoken_terms('st-1')
    end
  end

  describe '#get_spoken_terms_entries' do
    it 'sends the language in the query and splits the entries on newlines' do
      stub_request(:get, url('/v3/spoken-terms/st-1/entries?lang=en'))
        .with(headers: json_headers).to_return(reply(lang: 'en', entries: "a\nb\n"))

      result = client.get_spoken_terms_entries('st-1', 'en')

      expect([result.lang, result.entries]).to eq(['en', %w[a b]])
    end
  end

  describe '#replace_spoken_terms_list' do
    it 'takes a SpokenTermsEntries and a SpokenTerms object' do
      stub_request(:put, url('/v3/spoken-terms/st-1/term-lists'))
        .with(body: { lang: 'en', entries: "a\nb" }, headers: json_headers)
        .to_return(reply(lang: 'en', entry_count: 2))

      list = client.replace_spoken_terms_list(
        collection, DeepL::Resources::SpokenTermsEntries.new('en', %w[a b])
      )

      expect([list.lang, list.entry_count]).to eq(['en', 2])
    end

    it 'takes a hash and sends the extra body parameters' do
      stub_request(:put, url('/v3/spoken-terms/st-1/term-lists'))
        .with(body: { lang: 'de', entries: 'x', beta: true })
        .to_return(reply(lang: 'de', entry_count: 1))

      client.replace_spoken_terms_list('st-1', { lang: 'de', entries: ['x'] },
                                       extra_body_parameters: { beta: true })
    end
  end

  describe '#delete_spoken_terms and #delete_spoken_terms_list' do
    it 'send DELETE requests without a body and return nil' do
      stub_request(:delete, url('/v3/spoken-terms/st-1/term-lists?lang=de'))
        .with(headers: json_headers, body: no_body).to_return(status: 204)
      stub_request(:delete, url('/v3/spoken-terms/st-1'))
        .with(headers: json_headers, body: no_body).to_return(status: 204)

      expect(client.delete_spoken_terms_list('st-1', 'de')).to be_nil
      expect(client.delete_spoken_terms('st-1')).to be_nil
    end
  end

  describe 'collection IDs' do
    before do
      encoded = url('/v3/spoken-terms/a%20b%2Fc')
      stub_request(:get, encoded).to_return(reply(collection_json))
      stub_request(:patch, encoded).to_return(reply(collection_json))
      stub_request(:delete, encoded).to_return(status: 204)
      stub_request(:get, "#{encoded}/entries?lang=en").to_return(reply(lang: 'en', entries: ''))
      stub_request(:put, "#{encoded}/term-lists").to_return(reply(lang: 'en', entry_count: 0))
      stub_request(:delete, "#{encoded}/term-lists?lang=en").to_return(status: 204)
    end

    it 'are URL-encoded in every path' do
      id = 'a b/c'
      client.get_spoken_terms(id)
      client.update_spoken_terms(id, name: 'x')
      client.delete_spoken_terms(id)
      client.get_spoken_terms_entries(id, 'en')
      client.replace_spoken_terms_list(id, { lang: 'en', entries: ['x'] })
      client.delete_spoken_terms_list(id, 'en')
    end
  end
end
