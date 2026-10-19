# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'languages' do
  describe 'DeepL.languages' do
    let(:languages_reply) do
      reply([
              { lang: 'en', name: 'English', usable_as_source: true, usable_as_target: false },
              { lang: 'en-gb', name: 'English (British)', usable_as_source: false,
                usable_as_target: true, features: { formality: { status: 'stable' } } },
              { lang: 'de', name: 'German', usable_as_source: true, usable_as_target: true,
                features: { formality: { status: 'stable' } } },
              { lang: 'ja', name: 'Japanese', usable_as_source: true, usable_as_target: true }
            ])
    end

    def stub_languages
      stub_request(:get, url('/v3/languages?resource=translate_text'))
        .with(headers: json_headers).to_return(languages_reply)
    end

    it 'lists the source languages with upper-case codes by default' do
      stub_languages
      languages = DeepL.languages

      expect(languages.map { |l| [l.code, l.name] })
        .to eq([%w[EN English], %w[DE German], %w[JA Japanese]])
    end

    it 'lists the target languages with the formality support of each' do
      stub_languages
      languages = DeepL.languages(type: :target)

      expect(languages.map { |l| [l.code, l.supports_formality?] })
        .to eq([['EN-GB', true], ['DE', true], ['JA', false]])
    end

    it 'accepts the type as a string' do
      stub_languages
      expect(DeepL.languages('type' => 'target').map(&:code)).to eq(%w[EN-GB DE JA])
    end

    it 'raises NotSupported when asking a source language for formality support' do
      stub_languages
      expect { DeepL.languages.first.supports_formality? }
        .to raise_error(DeepL::Exceptions::NotSupported)
    end

    it 'raises ArgumentError for an unknown type without sending a request' do
      expect { DeepL.languages(type: :both) }.to raise_error(ArgumentError, /Unsupported `type`/)
    end
  end

  describe 'DeepL.languages_for_resource' do
    it 'sends the resource and every include value in the query' do
      stub_request(:get, url('/v3/languages?resource=translate_text&include=beta&include=external'))
        .with(headers: json_headers).to_return(reply([]))

      DeepL.languages_for_resource(:translate_text, include: %w[beta external])
    end

    it 'sends a single include value' do
      stub_request(:get, url('/v3/languages?resource=write&include=beta')).to_return(reply([]))

      DeepL.languages_for_resource('write', include: 'beta')
    end

    it 'parses the language, its usability and the feature support' do
      stub_request(:get, url('/v3/languages?resource=write')).to_return(
        reply([{ lang: 'de', name: 'German', status: 'stable', usable_as_source: true,
                 usable_as_target: false, features: { tone: { status: 'beta' } } }])
      )

      language = DeepL.languages_for_resource('write').first

      expect([language.code, language.name, language.status, language.usable_as_source?,
              language.usable_as_target?, language.features['tone'].status])
        .to eq(['de', 'German', 'stable', true, false, 'beta'])
      expect([language.supports?(:tone), language.supports?(:style)]).to eq([true, false])
    end

    it 'raises ArgumentError for an empty resource without sending a request' do
      expect { DeepL.languages_for_resource('') }.to raise_error(ArgumentError, /must not be empty/)
    end
  end

  describe 'DeepL.language_resources' do
    it 'parses the resources with the features and their language requirements' do
      stub_request(:get, url('/v3/languages/resources')).with(headers: json_headers).to_return(
        reply([{ name: 'translate_text',
                 features: [{ name: 'formality', needs_source_support: false,
                              needs_target_support: true }] }])
      )

      resource = DeepL.language_resources.first
      feature = resource.features['formality']

      expect([resource.resource, resource.supports?(:formality), resource.supports?(:glossary),
              feature.needs_source_support?, feature.needs_target_support?])
        .to eq(['translate_text', true, false, false, true])
    end
  end

  describe 'DeepL.glossaries.language_pairs' do
    it 'requests the glossary languages and pairs every source with every other target' do
      stub_request(:get,
                   url('/v3/languages?resource=glossary')).with(headers: json_headers).to_return(
                     reply([{ lang: 'en', usable_as_source: true, usable_as_target: true },
                            { lang: 'de', usable_as_source: true, usable_as_target: true },
                            { lang: 'fr', usable_as_source: false, usable_as_target: true }])
                   )

      pairs = DeepL.glossaries.language_pairs

      expect(pairs.map(&:to_s)).to eq(['en - de', 'en - fr', 'de - en', 'de - fr'])
    end
  end
end
