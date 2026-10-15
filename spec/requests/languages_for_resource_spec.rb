# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::LanguagesForResource do
  subject(:languages_obj) { described_class.new(api, resource, options) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:resource) { 'translate_text' }
  let(:options) { {} }

  describe '#initialize' do
    it 'sends the resource as a query parameter' do
      expect(languages_obj.to_s).to eq('GET /v3/languages?resource=translate_text')
    end

    context 'when the resource is a symbol' do
      let(:resource) { :glossary }

      it 'converts it to a string' do
        expect(languages_obj.to_s).to eq('GET /v3/languages?resource=glossary')
      end
    end

    context 'when include values are given' do
      let(:options) { { include: %w[beta external] } }

      it 'repeats the include parameter' do
        expect(languages_obj.to_s)
          .to eq('GET /v3/languages?resource=translate_text&include=beta&include=external')
      end
    end

    context 'when a single include value is given' do
      let(:options) { { 'include' => 'beta' } }

      it 'sends it once' do
        expect(languages_obj.to_s).to eq('GET /v3/languages?resource=translate_text&include=beta')
      end
    end

    context 'when the resource is empty' do
      let(:resource) { '' }

      it 'raises ArgumentError' do
        expect { languages_obj }.to raise_error(ArgumentError, /resource must not be empty/)
      end
    end
  end
end
