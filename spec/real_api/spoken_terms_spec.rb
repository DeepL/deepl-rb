# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client spoken terms' do
  let(:client) do
    DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  end

  def term_lists_of(collection)
    collection.term_lists.map { |list| [list.lang, list.entry_count] }
  end

  it 'creates, reads, updates, replaces and deletes a spoken terms collection' do
    name = unique_name('spokenTerms')

    term_list = DeepL::Resources::SpokenTermsEntries.new('en', %w[DeepL webhook])
    created = client.create_spoken_terms(name, [term_list])
    id = created.spoken_terms_id
    begin
      expect(created.name).to eq(name)
      expect(created.creation_time).to be_a(Time)
      expect(term_lists_of(created)).to eq([['en', 2]])

      fetched = retry_while_not_found { client.get_spoken_terms(id) }
      expect([fetched.spoken_terms_id, fetched.name]).to eq([id, name])
      expect(client.list_spoken_terms.map(&:spoken_terms_id)).to include(id)

      more = [{ lang: 'en', entries: ['authentication'] }]
      updated = client.update_spoken_terms(created, term_lists: more)
      expect(term_lists_of(updated)).to eq([['en', 3]])
      entries = client.get_spoken_terms_entries(id, 'en')
      expect(entries.lang).to eq('en')
      expect(entries.entries).to contain_exactly('DeepL', 'authentication', 'webhook')

      replaced = client.replace_spoken_terms_list(id, { lang: 'en', entries: ['API'] })
      expect([replaced.lang, replaced.entry_count]).to eq(['en', 1])
      expect(client.get_spoken_terms_entries(id, 'en').entries).to eq(['API'])

      added = client.replace_spoken_terms_list(
        created, DeepL::Resources::SpokenTermsEntries.new('de', ['Schnittstelle'])
      )
      expect([added.lang, added.entry_count]).to eq(['de', 1])
      expect(client.delete_spoken_terms_list(id, 'de')).to be_nil
      expect(term_lists_of(client.get_spoken_terms(id))).to eq([['en', 1]])

      expect(client.delete_spoken_terms(id)).to be_nil
      expect { client.get_spoken_terms(id) }.to raise_error(DeepL::Exceptions::NotFound)
    ensure
      delete_quietly { client.delete_spoken_terms(id) }
    end
  end
end
