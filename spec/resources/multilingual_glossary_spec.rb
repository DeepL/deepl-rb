# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Resources::MultilingualGlossary do
  subject(:glossary) do
    described_class.new({
                          'glossary_id' => 'def3a26b-3e84-45b3-84ae-0c0aaf3525f7',
                          'name' => 'Mein Glossar',
                          'creation_time' => '2026-01-15T14:16:18.329Z',
                          'dictionaries' => [
                            { 'source_lang' => 'en', 'target_lang' => 'de', 'entry_count' => 1 },
                            { 'source_lang' => 'en', 'target_lang' => 'fr', 'entry_count' => 2 }
                          ]
                        }, nil, nil)
  end

  describe '#initialize' do
    context 'when building a basic object' do
      it 'creates a resource' do
        expect(glossary).to be_a(described_class)
      end

      it 'assigns the attributes' do # rubocop:disable RSpec/MultipleExpectations
        expect(glossary.id).to eq('def3a26b-3e84-45b3-84ae-0c0aaf3525f7')
        expect(glossary.name).to eq('Mein Glossar')
        expect(glossary.creation_time).to eq('2026-01-15T14:16:18.329Z')
        expect(glossary.dictionaries).to be_an(Array)
        expect(glossary.dictionaries.length).to eq(2)
        expect(glossary.dictionaries.first)
          .to be_a(DeepL::Resources::MultilingualGlossaryDictionary)
        expect(glossary.dictionaries.first.source_lang).to eq('en')
        expect(glossary.dictionaries.first.target_lang).to eq('de')
        expect(glossary.dictionaries.first.entry_count).to eq(1)
      end
    end
  end
end
