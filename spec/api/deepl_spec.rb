# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable-next RSpec/StubbedMock
describe DeepL do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:deepl) { described_class.dup }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  describe '#configure' do
    context 'when providing no block' do
      let(:configuration) { DeepL::Configuration.new }

      before do
        deepl.configure
      end

      it 'uses default configuration' do
        expect(deepl.configuration).to eq(configuration)
      end
    end

    context 'when providing a valid configuration' do
      let(:configuration) do
        DeepL::Configuration.new({ auth_key: 'VALID', host: 'http://www.example.org',
                                   version: 'v1' })
      end

      before do
        deepl.configure do |config|
          config.auth_key = configuration.auth_key
          config.host = configuration.host
          config.version = configuration.version
        end
      end

      it 'uses the provided configuration' do
        expect(deepl.configuration).to eq(configuration)
      end
    end

    context 'when providing an invalid configuration' do
      it 'raises an error' do
        expect { deepl.configure { |c| c.auth_key = '' } }
          .to raise_error(DeepL::Exceptions::Error)
      end
    end
  end

  describe '#translate' do
    let(:request) { instance_double(DeepL::Requests::Translate, request: 'result') }

    before { deepl.configure }

    it 'delegates to DeepL::Requests::Translate with the given arguments' do
      options = { formality: 'more' }
      additional_headers = { 'X-DeepL-Reporting-Tag' => 'tag' }
      expect(DeepL::Requests::Translate).to receive(:new)
        .with(deepl.api, 'Sample', 'EN', 'ES', options, additional_headers)
        .and_return(request)

      expect(deepl.translate('Sample', 'EN', 'ES', options, additional_headers)).to eq('result')
    end

    it 'defaults options and additional_headers to empty hashes' do
      expect(DeepL::Requests::Translate).to receive(:new)
        .with(deepl.api, 'Sample', 'EN', 'ES', {}, {})
        .and_return(request)

      deepl.translate('Sample', 'EN', 'ES')
    end
  end

  describe '#rephrase' do
    let(:request) { instance_double(DeepL::Requests::Rephrase, request: 'result') }

    before { deepl.configure }

    it 'delegates to DeepL::Requests::Rephrase with the given arguments' do
      options = { foo: 'bar' }
      additional_headers = { 'X-DeepL-Reporting-Tag' => 'tag' }
      expect(DeepL::Requests::Rephrase).to receive(:new)
        .with(deepl.api, 'Sample', 'DE', 'business', 'friendly', options, additional_headers)
        .and_return(request)

      result = deepl.rephrase('Sample', 'DE', 'business', 'friendly', options, additional_headers)
      expect(result).to eq('result')
    end

    it 'defaults the optional arguments' do
      expect(DeepL::Requests::Rephrase).to receive(:new)
        .with(deepl.api, 'Sample', nil, nil, nil, {}, {})
        .and_return(request)

      deepl.rephrase('Sample')
    end
  end

  describe '#usage' do
    let(:request) { instance_double(DeepL::Requests::Usage, request: 'result') }

    before { deepl.configure }

    it 'delegates to DeepL::Requests::Usage with the given options' do
      options = { foo: 'bar' }
      expect(DeepL::Requests::Usage).to receive(:new).with(deepl.api, options).and_return(request)

      expect(deepl.usage(options)).to eq('result')
    end

    it 'defaults options to an empty hash' do
      expect(DeepL::Requests::Usage).to receive(:new).with(deepl.api, {}).and_return(request)

      deepl.usage
    end
  end

  describe '#languages' do
    let(:request) { instance_double(DeepL::Requests::Languages, request: 'result') }

    before { deepl.configure }

    it 'delegates to DeepL::Requests::Languages with the given options' do
      options = { type: :target }
      expect(DeepL::Requests::Languages).to receive(:new).with(deepl.api, options)
                                                         .and_return(request)

      expect(deepl.languages(options)).to eq('result')
    end

    it 'defaults options to an empty hash' do
      expect(DeepL::Requests::Languages).to receive(:new).with(deepl.api, {}).and_return(request)

      deepl.languages
    end
  end

  describe '#glossaries' do
    before { deepl.configure }

    it 'returns a GlossaryApi instance built with the configured api' do
      expect(deepl.glossaries).to be_a(DeepL::GlossaryApi)
    end

    describe 'GlossaryApi#create' do
      it 'delegates to DeepL::Requests::Glossary::Create' do
        request = instance_double(DeepL::Requests::Glossary::Create, request: 'result')
        entries = [%w[Hello Hola]]
        expect(DeepL::Requests::Glossary::Create).to receive(:new)
          .with(deepl.api, 'Mi Glosario', 'EN', 'ES', entries, {})
          .and_return(request)

        deepl.glossaries.create('Mi Glosario', 'EN', 'ES', entries)
      end
    end

    describe 'GlossaryApi#find' do
      it 'delegates to DeepL::Requests::Glossary::Find' do
        request = instance_double(DeepL::Requests::Glossary::Find, request: 'result')
        expect(DeepL::Requests::Glossary::Find).to receive(:new)
          .with(deepl.api, 'glossary-id', {})
          .and_return(request)

        deepl.glossaries.find('glossary-id')
      end
    end

    describe 'GlossaryApi#list' do
      it 'delegates to DeepL::Requests::Glossary::List' do
        request = instance_double(DeepL::Requests::Glossary::List, request: 'result')
        expect(DeepL::Requests::Glossary::List).to receive(:new).with(deepl.api, {})
                                                                .and_return(request)

        deepl.glossaries.list
      end
    end

    describe 'GlossaryApi#destroy' do
      it 'delegates to DeepL::Requests::Glossary::Destroy' do
        request = instance_double(DeepL::Requests::Glossary::Destroy, request: 'result')
        expect(DeepL::Requests::Glossary::Destroy).to receive(:new)
          .with(deepl.api, 'glossary-id', {})
          .and_return(request)

        deepl.glossaries.destroy('glossary-id')
      end
    end

    describe 'GlossaryApi#entries' do
      it 'delegates to DeepL::Requests::Glossary::Entries' do
        request = instance_double(DeepL::Requests::Glossary::Entries, request: 'result')
        expect(DeepL::Requests::Glossary::Entries).to receive(:new)
          .with(deepl.api, 'glossary-id', {})
          .and_return(request)

        deepl.glossaries.entries('glossary-id')
      end
    end

    describe 'GlossaryApi#language_pairs' do
      it 'delegates to DeepL::Requests::Glossary::LanguagePairs' do
        request = instance_double(DeepL::Requests::Glossary::LanguagePairs, request: 'result')
        expect(DeepL::Requests::Glossary::LanguagePairs).to receive(:new).with(deepl.api, {})
                                                                         .and_return(request)

        deepl.glossaries.language_pairs
      end
    end
  end

  describe '#document' do
    before { deepl.configure }

    it 'returns a DocumentApi instance built with the configured api' do
      expect(deepl.document).to be_a(DeepL::DocumentApi)
    end

    describe 'DocumentApi#upload' do
      it 'delegates to DeepL::Requests::Document::Upload' do
        request = instance_double(DeepL::Requests::Document::Upload, request: 'result')
        expect(DeepL::Requests::Document::Upload).to receive(:new)
          .with(deepl.api, 'path', 'EN', 'ES', 'file.txt', {}, {})
          .and_return(request)

        deepl.document.upload('path', 'EN', 'ES', 'file.txt')
      end
    end

    describe 'DocumentApi#get_status' do
      it 'delegates to DeepL::Requests::Document::GetStatus' do
        request = instance_double(DeepL::Requests::Document::GetStatus, request: 'result')
        handle = DeepL::Resources::DocumentHandle.new('doc-id', 'doc-key', nil, nil)
        expect(DeepL::Requests::Document::GetStatus).to receive(:new)
          .with(deepl.api, 'doc-id', 'doc-key', {}, {})
          .and_return(request)

        deepl.document.get_status(handle)
      end
    end

    describe 'DocumentApi#download' do
      it 'delegates to DeepL::Requests::Document::Download' do
        request = instance_double(DeepL::Requests::Document::Download, request: 'result')
        handle = DeepL::Resources::DocumentHandle.new('doc-id', 'doc-key', nil, nil)
        expect(DeepL::Requests::Document::Download).to receive(:new)
          .with(deepl.api, 'doc-id', 'doc-key', 'output-path')
          .and_return(request)

        deepl.document.download(handle, 'output-path')
      end
    end
  end
end
