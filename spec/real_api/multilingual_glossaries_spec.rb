# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client multilingual glossaries' do
  let(:client) do
    DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  end

  def pairs_of(glossary)
    glossary.dictionaries.map { |d| "#{d.source_lang}-#{d.target_lang}" }
  end

  it 'creates, reads, updates, replaces and deletes a multilingual glossary' do
    name = unique_name('glossary-v3')
    dictionaries = [
      DeepL::Resources::MultilingualGlossaryDictionaryEntries.new('EN', 'DE', [%w[Apple Apfel]]),
      { source_lang: 'EN', target_lang: 'FR', entries: [%w[Apple Pomme]] }
    ]

    glossary = client.create_multilingual_glossary(name, dictionaries)
    begin
      expect(glossary.name).to eq(name)
      expect(glossary.creation_time).to be_a(Time)
      expect(pairs_of(glossary)).to contain_exactly('en-de', 'en-fr')

      fetched = retry_while_not_found { client.get_multilingual_glossary(glossary) }
      expect([fetched.id, fetched.name]).to eq([glossary.id, name])
      expect(client.list_multilingual_glossaries.map(&:id)).to include(glossary.id)

      entries = client.get_multilingual_glossary_dictionary_entries(glossary, 'EN', 'DE')
      expect(entries.entries).to eq([%w[Apple Apfel]])

      pear = { source_lang: 'EN', target_lang: 'DE', entries: [%w[Pear Birne]] }
      updated = client.update_multilingual_glossary(glossary, name: "#{name}-renamed",
                                                              dictionaries: [pear])
      expect(updated.name).to eq("#{name}-renamed")

      replaced = client.replace_multilingual_glossary_dictionary(
        glossary, { source_lang: 'EN', target_lang: 'DE', entries: [%w[Cherry Kirsche]] }
      )
      expect([replaced.source_lang, replaced.target_lang, replaced.entry_count])
        .to eq(['en', 'de', 1])

      expect(client.delete_multilingual_glossary_dictionary(glossary, 'EN', 'FR')).to be_nil
    ensure
      delete_quietly { client.delete_multilingual_glossary(glossary) }
    end
  end
end
