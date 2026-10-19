# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL.glossaries' do
  it 'sends the v2 glossary requests: create, get, list, entries and delete' do
    glossaries = DeepL.glossaries
    name = unique_name('glossary')
    entries = [%w[Apple Apfel], %w[Banana Banane]]

    glossary = glossaries.create(name, 'EN', 'DE', entries)
    begin
      expect([glossary.name, glossary.source_lang, glossary.target_lang, glossary.entry_count])
        .to eq([name, 'en', 'de', 2])

      fetched = retry_while_not_found { glossaries.find(glossary.id) }
      expect([fetched.id, fetched.name]).to eq([glossary.id, name])
      expect(glossaries.list.map(&:id)).to include(glossary.id)
      expect(glossaries.entries(glossary.id)).to match_array(entries)
    ensure
      delete_quietly { glossaries.destroy(glossary.id) }
    end
    expect { glossaries.find(glossary.id) }.to raise_error(DeepL::Exceptions::NotFound)
  end
end
