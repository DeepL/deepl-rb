# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::MultilingualGlossary::UpdateDictionary do
  subject(:update_dictionary) do
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
  let(:target_lang) { 'fr' }
  let(:entries) { [%w[Hello Bonjour]] }
  let(:options) { {} }

  describe '#initialize' do
    it 'creates a request object' do
      expect(update_dictionary).to be_a(described_class)
    end

    it 'defaults the entries format to tsv' do
      expect(update_dictionary.entries_format).to eq('tsv')
    end
  end

  describe '#to_s' do
    it 'targets the v3 glossary endpoint with a PATCH' do
      expect(update_dictionary.to_s).to eq("PATCH /v3/glossaries/#{id}")
    end
  end

  describe 'entry serialization' do
    it 'serializes array entries into a tsv string' do
      expect(update_dictionary.send(:entries_to_string, entries)).to eq("Hello\tBonjour")
    end
  end
end
