# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'languages' do
  it 'sends GET /v3/languages and parses the source languages' do
    languages = DeepL.languages
    codes = languages.map(&:code)

    expect(codes).to include('EN')
    expect(codes).to eq(codes.map(&:upcase))
    expect(languages.map(&:name)).to all(be_a(String))
  end

  it 'sends GET /v3/languages/resources and parses the resources and their features' do
    resources = DeepL.language_resources

    translate_text = resources.find { |resource| resource.resource == 'translate_text' }
    expect(translate_text.features['glossary'].needs_source_support?).to be(true)
    expect(translate_text.features['glossary'].needs_target_support?).to be(true)
  end
end
