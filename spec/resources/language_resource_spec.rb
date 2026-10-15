# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Resources::LanguageResource do
  subject(:resource) { described_class.new(json, nil, nil) }

  let(:json) do
    { 'name' => 'translate_text',
      'features' => [{ 'name' => 'formality', 'needs_target_support' => true },
                     { 'name' => 'glossary', 'needs_source_support' => true,
                       'needs_target_support' => true }] }
  end

  it 'maps the resource name' do
    expect(resource.resource).to eq('translate_text')
    expect(resource.to_s).to eq('translate_text')
  end

  it 'maps the features by name' do
    expect(resource.features.keys).to eq(%w[formality glossary])
    expect(resource.features.values).to all(be_a(DeepL::Resources::ResourceFeature))
    expect(resource).to be_supports(:glossary)
    expect(resource).not_to be_supports('tone')
  end

  it 'defaults absent needs_*_support flags to false' do
    formality = resource.features['formality']
    expect(formality.name).to eq('formality')
    expect(formality).not_to be_needs_source_support
    expect(formality).to be_needs_target_support
    expect(resource.features['glossary']).to be_needs_source_support
  end

  context 'when the resource has no features' do
    let(:json) { { 'name' => 'style_rules', 'features' => [] } }

    it 'returns no features' do
      expect(resource.features).to eq({})
    end
  end
end
