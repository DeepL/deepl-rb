# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL.multilingual_glossaries' do
  it 'sends the v3 glossary requests: create, get, list, entries, rename, replace and delete' do
    glossaries = DeepL.multilingual_glossaries
    name = unique_name('glossary-v3')
    dictionaries = [
      { source_lang: 'EN', target_lang: 'DE', entries: [%w[Apple Apfel]] },
      { source_lang: 'EN', target_lang: 'FR', entries: [%w[Apple Pomme]] }
    ]

    glossary = glossaries.create(name, dictionaries)
    begin
      expect(glossary.name).to eq(name)
      expect(glossary.dictionaries.map { |d| "#{d.source_lang}-#{d.target_lang}" })
        .to contain_exactly('en-de', 'en-fr')

      fetched = retry_while_not_found { glossaries.find(glossary.id) }
      expect([fetched.id, fetched.name]).to eq([glossary.id, name])
      expect(glossaries.list.map(&:id)).to include(glossary.id)

      dictionary = glossaries.entries(glossary.id, 'EN', 'DE').first
      expect(dictionary.entries.split("\n")).to eq(["Apple\tApfel"])

      renamed = glossaries.update_name(glossary.id, "#{name}-renamed")
      expect(renamed.name).to eq("#{name}-renamed")

      replaced = glossaries.replace_dictionary(glossary.id, 'EN', 'DE', [%w[Cherry Kirsche]])
      expect([replaced.source_lang, replaced.target_lang, replaced.entry_count])
        .to eq(['en', 'de', 1])

      glossaries.destroy_dictionary(glossary.id, 'EN', 'FR')
    ensure
      delete_quietly { glossaries.destroy(glossary.id) }
    end
  end
end
