# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::MultilingualGlossary::ReplaceDictionary do
  subject(:replace_dictionary) do
    described_class.new(api, id, source_lang, target_lang, entries, options)
  end

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:id) { '9ab5dac2-b7b2-4b4a-808a-e8e305df5ecb' }
  let(:source_lang) { 'en' }
  let(:target_lang) { 'de' }
  let(:entries) { [%w[Hello Hallo], %w[World Welt]] }
  let(:options) { {} }

  describe '#initialize' do
    it 'creates a request object' do
      expect(replace_dictionary).to be_a(described_class)
    end

    it 'defaults the entries format to tsv' do
      expect(replace_dictionary.entries_format).to eq('tsv')
    end
  end

  describe '#to_s' do
    it 'targets the dictionaries endpoint with a PUT' do
      expect(replace_dictionary.to_s).to eq("PUT /v3/glossaries/#{id}/dictionaries")
    end
  end

  describe 'entry serialization' do
    it 'serializes array entries into a tsv string' do
      serialized = replace_dictionary.send(:entries_to_string, entries)
      expect(serialized).to eq("Hello\tHallo\nWorld\tWelt")
    end
  end
end
