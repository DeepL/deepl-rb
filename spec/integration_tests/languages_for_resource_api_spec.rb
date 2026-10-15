# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

# Covers GET /v3/languages and GET /v3/languages/resources.
describe 'DeepL.languages_for_resource and DeepL.language_resources' do # rubocop:disable RSpec/DescribeClass
  include_context 'with a live mock server'

  describe 'DeepL.languages_for_resource' do
    it 'returns the languages for translate_text with source/target flags and features' do
      languages = DeepL.languages_for_resource('translate_text')

      expect(languages).not_to be_empty
      expect(languages).to all(be_a(DeepL::Resources::LanguageSupport))
      expect(languages.map(&:code)).to include('de', 'en')
      expect(languages.select(&:usable_as_target?)).not_to be_empty
      expect(languages.select(&:usable_as_source?)).not_to be_empty
      expect(languages.map(&:status)).to all(be_a(String))
      expect(languages).to(be_any { |language| language.supports?(:formality) })
    end

    it 'accepts include values' do
      languages = DeepL.languages_for_resource(:translate_text, include: %w[beta external])

      expect(languages).not_to be_empty
      expect(languages).to all(be_a(DeepL::Resources::LanguageSupport))
    end

    it 'raises AuthorizationFailed when the auth key is invalid' do
      request = DeepL::Requests::LanguagesForResource.new(unauthorized_api, 'translate_text')

      expect { request.request }.to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end
  end

  describe 'DeepL.language_resources' do
    it 'returns the resources with their features' do
      resources = DeepL.language_resources

      expect(resources).to all(be_a(DeepL::Resources::LanguageResource))
      expect(resources.map(&:resource)).to include('translate_text')

      translate_text = resources.find { |resource| resource.resource == 'translate_text' }
      expect(translate_text.features.values).to all(be_a(DeepL::Resources::ResourceFeature))
      expect(translate_text).to be_supports(:formality)
      expect(translate_text.features['formality']).to be_needs_target_support
    end

    it 'raises AuthorizationFailed when the auth key is invalid' do
      request = DeepL::Requests::LanguageResources.new(unauthorized_api)

      expect { request.request }.to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end
  end
end
