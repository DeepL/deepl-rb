# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL.spoken_terms' do
  def term_lists_of(collection)
    collection.term_lists.map { |list| [list.lang, list.entry_count] }
  end

  it 'creates, reads, updates, replaces and deletes a spoken terms collection' do
    spoken_terms = DeepL.spoken_terms
    name = unique_name('spokenTerms')

    term_list = DeepL::Resources::SpokenTermsEntries.new('en', %w[DeepL webhook])
    created = spoken_terms.create(name, [term_list])
    begin
      expect(created.name).to eq(name)
      expect(created.creation_time).to be_a(Time)
      expect(term_lists_of(created)).to eq([['en', 2]])

      fetched = retry_while_not_found { spoken_terms.find(created.id) }
      expect([fetched.id, fetched.name]).to eq([created.id, name])
      expect(spoken_terms.list.map(&:id)).to include(created.id)

      updated = spoken_terms.update(created,
                                    term_lists: [{ lang: 'en', entries: ['authentication'] }])
      expect(term_lists_of(updated)).to eq([['en', 3]])
      entries = spoken_terms.entries(created.id, 'en')
      expect(entries.lang).to eq('en')
      expect(entries.entries).to contain_exactly('DeepL', 'authentication', 'webhook')

      replaced = spoken_terms.replace_term_list(created.id, 'en', ['API'])
      expect([replaced.lang, replaced.entry_count]).to eq(['en', 1])
      expect(spoken_terms.entries(created.id, 'en').entries).to eq(['API'])

      added = spoken_terms.replace_term_list(created.id, 'de', ['Schnittstelle'])
      expect([added.lang, added.entry_count]).to eq(['de', 1])
      spoken_terms.destroy_term_list(created.id, 'de')
      expect(term_lists_of(spoken_terms.find(created.id))).to eq([['en', 1]])

      spoken_terms.destroy(created.id)
      expect { spoken_terms.find(created.id) }.to raise_error(DeepL::Exceptions::NotFound)
    ensure
      delete_quietly { spoken_terms.destroy(created.id) }
    end
  end
end
