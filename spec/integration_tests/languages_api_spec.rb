# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

# Covers GET /v3/languages?resource=translate_text.
describe 'DeepL.languages' do # rubocop:disable RSpec/DescribeClass
  describe 'source languages' do
    it 'returns a non-empty array of Language resources with common codes' do
      languages = DeepL.languages

      expect(languages).to be_an(Array)
      expect(languages).not_to be_empty
      expect(languages).to all(be_a(DeepL::Resources::Language))
      expect(languages.first).to respond_to(:code, :name)

      codes = languages.map(&:code)
      expect(codes).to include('EN', 'DE')
    end
  end

  describe 'target languages' do
    it 'returns target entries that include both formality-supporting and non-supporting members' do
      languages = DeepL.languages(type: :target)

      expect(languages).to be_an(Array)
      expect(languages).not_to be_empty
      expect(languages).to all(be_a(DeepL::Resources::Language))

      formalities = languages.map(&:supports_formality?)
      expect(formalities).to include(true)
      expect(formalities).to include(false)
    end

    it 'raises NotSupported when supports_formality? is called on a source-language entry' do
      source_languages = DeepL.languages

      expect { source_languages.first.supports_formality? }
        .to raise_error(DeepL::Exceptions::NotSupported)
    end
  end

  describe 'source vs target counts' do
    it 'returns sensible (>20) counts for both source and target listings' do
      source_languages = DeepL.languages
      target_languages = DeepL.languages(type: :target)

      expect(source_languages.size).to be > 20
      expect(target_languages.size).to be > 20
    end
  end
end
