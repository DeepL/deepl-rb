# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::MultilingualGlossary::DestroyDictionary do
  subject(:destroy_dictionary) { described_class.new(api, id, source_lang, target_lang) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:id) { '9ab5dac2-b7b2-4b4a-808a-e8e305df5ecb' }
  let(:source_lang) { 'en' }
  let(:target_lang) { 'de' }

  describe '#initialize' do
    it 'creates a request object' do
      expect(destroy_dictionary).to be_a(described_class)
    end
  end

  describe '#to_s' do
    it 'targets the dictionaries endpoint with the language pair as query params' do
      expect(destroy_dictionary.to_s)
        .to eq("DELETE /v3/glossaries/#{id}/dictionaries?source_lang=en&target_lang=de")
    end
  end
end
