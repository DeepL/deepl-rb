# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Resources::LanguageSupport do
  subject(:language) { described_class.new(json, nil, nil) }

  let(:json) do
    { 'lang' => 'de', 'name' => 'German', 'status' => 'stable', 'usable_as_source' => true,
      'usable_as_target' => false, 'features' => { 'formality' => { 'status' => 'beta' } } }
  end

  it 'maps the attributes' do
    expect(language.code).to eq('de')
    expect(language.name).to eq('German')
    expect(language.status).to eq('stable')
    expect(language).to be_usable_as_source
    expect(language).not_to be_usable_as_target
    expect(language.to_s).to eq('German (de)')
  end

  it 'maps the features' do
    expect(language.features['formality']).to be_a(DeepL::Resources::LanguageFeature)
    expect(language.features['formality'].status).to eq('beta')
    expect(language).to be_supports(:formality)
    expect(language).not_to be_supports('glossary')
  end

  context 'when the features key is missing' do
    let(:json) { { 'lang' => 'en', 'name' => 'English', 'status' => 'stable' } }

    it 'returns no features' do
      expect(language.features).to eq({})
      expect(language).not_to be_usable_as_source
    end
  end
end
