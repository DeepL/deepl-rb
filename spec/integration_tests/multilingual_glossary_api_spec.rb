# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::MultilingualGlossaryApi do
  let(:default_dictionary) do
    {
      source_lang: 'en',
      target_lang: 'de',
      entries: [%w[Hello Hallo], %w[World Welt]]
    }
  end
  let(:default_glossary_args) do
    {
      name: 'Integration Test Multilingual Glossary',
      dictionaries: [default_dictionary]
    }
  end

  def create_multilingual_glossary(args = default_glossary_args)
    DeepL.multilingual_glossaries.create(args[:name], args[:dictionaries])
  end

  def destroy_multilingual_glossary(glossary_id)
    DeepL.multilingual_glossaries.destroy(glossary_id)
  rescue StandardError
    nil
  end

  describe 'happy path lifecycle' do
    it 'creates, lists, and finds a multilingual glossary' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      glossary = create_multilingual_glossary
      begin
        expect(glossary).to be_a(DeepL::Resources::MultilingualGlossary)
        expect(glossary.id).to be_a(String)
        expect(glossary.name).to eq(default_glossary_args[:name])
        expect(glossary.dictionaries).to be_an(Array)
        expect(glossary.dictionaries.length).to eq(1)
        expect(glossary.dictionaries.first).to be_a(DeepL::Resources::MultilingualGlossaryDictionary)
        expect(glossary.dictionaries.first.source_lang.downcase).to eq('en')
        expect(glossary.dictionaries.first.target_lang.downcase).to eq('de')
        expect(glossary.dictionaries.first.entry_count).to eq(2)

        listed = DeepL.multilingual_glossaries.list
        expect(listed).to be_an(Array)
        expect(listed.map(&:id)).to include(glossary.id)

        found = DeepL.multilingual_glossaries.find(glossary.id)
        expect(found).to be_a(DeepL::Resources::MultilingualGlossary)
        expect(found.id).to eq(glossary.id)
        expect(found.name).to eq(glossary.name)
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end
  end

  describe '#create_with_csv' do
    it 'creates a multilingual glossary from CSV content' do # rubocop:disable RSpec/ExampleLength
      csv_content = "Hello,Hallo\nWorld,Welt\n"
      glossary = DeepL.multilingual_glossaries.create_with_csv(
        'CSV Multilingual Glossary', 'en', 'de', csv_content
      )
      begin
        expect(glossary).to be_a(DeepL::Resources::MultilingualGlossary)
        expect(glossary.dictionaries.length).to eq(1)
        expect(glossary.dictionaries.first.entry_count).to eq(2)
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end
  end

  describe '#entries' do
    it 'returns the dictionary entries for the given language pair' do # rubocop:disable RSpec/ExampleLength
      glossary = create_multilingual_glossary
      begin
        dictionaries = DeepL.multilingual_glossaries.entries(glossary.id, 'en', 'de')
        expect(dictionaries).to be_an(Array)
        expect(dictionaries.length).to eq(1)
        dictionary = dictionaries.first
        expect(dictionary).to be_a(DeepL::Resources::MultilingualGlossaryDictionaryEntries)
        expect(dictionary.source_lang.downcase).to eq('en')
        expect(dictionary.target_lang.downcase).to eq('de')
        expect(dictionary.entries).to be_a(String)
        expect(dictionary.entries_format).to eq('tsv')
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end
  end

  describe '#update_name' do
    it 'updates the name of a multilingual glossary' do
      glossary = create_multilingual_glossary
      begin
        updated = DeepL.multilingual_glossaries.update_name(glossary.id, 'Renamed Glossary')
        expect(updated).to be_a(DeepL::Resources::MultilingualGlossary)
        expect(updated.name).to eq('Renamed Glossary')
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end
  end

  describe '#update_dictionary' do
    it 'updates or creates a dictionary in the glossary' do # rubocop:disable RSpec/ExampleLength
      glossary = create_multilingual_glossary
      begin
        updated = DeepL.multilingual_glossaries.update_dictionary(
          glossary.id, 'en', 'fr', [%w[Hello Bonjour]]
        )
        expect(updated).to be_a(DeepL::Resources::MultilingualGlossary)
        language_pairs = updated.dictionaries.map do |d|
          [d.source_lang, d.target_lang].map(&:downcase)
        end
        expect(language_pairs).to include(%w[en fr])
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end
  end

  describe '#replace_dictionary' do
    it 'replaces the entries of an existing dictionary' do # rubocop:disable RSpec/ExampleLength
      glossary = create_multilingual_glossary
      begin
        replaced = DeepL.multilingual_glossaries.replace_dictionary(
          glossary.id, 'en', 'de', [%w[Hello Hallo], %w[World Welt], %w[car Auto]]
        )
        expect(replaced).to be_a(DeepL::Resources::MultilingualGlossaryDictionary)
        expect(replaced.source_lang.downcase).to eq('en')
        expect(replaced.target_lang.downcase).to eq('de')
        expect(replaced.entry_count).to eq(3)
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end

    it 'replaces an existing dictionary using CSV content' do # rubocop:disable RSpec/ExampleLength
      glossary = create_multilingual_glossary
      begin
        csv_content = "Hello,Hallo\nWorld,Welt\ncar,Auto\n"
        replaced = DeepL.multilingual_glossaries.replace_dictionary_with_csv(
          glossary.id, 'en', 'de', csv_content
        )
        expect(replaced).to be_a(DeepL::Resources::MultilingualGlossaryDictionary)
        expect(replaced.entry_count).to eq(3)
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end
  end

  describe '#destroy_dictionary' do
    it 'deletes a dictionary from the glossary' do # rubocop:disable RSpec/ExampleLength
      args = default_glossary_args.merge(
        dictionaries: [
          default_dictionary,
          { source_lang: 'en', target_lang: 'fr', entries: [%w[Hello Bonjour]] }
        ]
      )
      glossary = create_multilingual_glossary(args)
      begin
        result = DeepL.multilingual_glossaries.destroy_dictionary(glossary.id, 'en', 'fr')
        expect(result.transform_values(&:downcase)).to eq(source_lang: 'en', target_lang: 'fr')
      ensure
        destroy_multilingual_glossary(glossary.id)
      end
    end
  end

  describe '#destroy' do
    it 'returns the id of the destroyed glossary' do
      glossary = create_multilingual_glossary
      expect(DeepL.multilingual_glossaries.destroy(glossary.id)).to eq(glossary.id)
    end
  end

  describe 'spec validation', :mock_server_only do
    it 'rejects a request with a type-violating dictionaries entry' do
      expect do
        DeepL.multilingual_glossaries.create(
          'Type-Violating Glossary',
          [{ source_lang: 123, target_lang: 'de', entries: [%w[Hello Hallo]] }]
        )
      end.to raise_error(DeepL::Exceptions::BadRequest)
    end
  end
end
