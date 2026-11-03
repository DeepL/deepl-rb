# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client v2 glossaries' do
  let(:client) { real_api_client }

  it 'creates, reads, lists and deletes a v2 glossary' do
    name = unique_name('glossary')
    entries = { 'Apple' => 'Apfel', 'Banana' => 'Banane' }

    glossary = client.create_glossary(name, 'EN', 'DE', entries)
    begin
      expect([glossary.name, glossary.source_lang, glossary.target_lang, glossary.entry_count])
        .to eq([name, 'en', 'de', 2])

      fetched = retry_while_not_found { client.get_glossary(glossary.id) }
      expect([fetched.id, fetched.name]).to eq([glossary.id, name])
      expect(client.list_glossaries.map(&:id)).to include(glossary.id)
      expect(client.get_glossary_entries(glossary)).to eq(entries)

      expect(client.delete_glossary(glossary)).to be_nil
    ensure
      delete_quietly { client.delete_glossary(glossary) }
    end
    expect { client.get_glossary(glossary) }.to raise_error(DeepL::Exceptions::NotFound)
  end
end
