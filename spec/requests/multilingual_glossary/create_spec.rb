# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::MultilingualGlossary::Create do
  subject(:create) { described_class.new(api, name, dictionaries, options) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:name) { 'Mi Glosario' }
  let(:dictionaries) do
    [{ source_lang: 'EN', target_lang: 'ES', entries: [%w[Hello Hola], %w[World Mundo]] }]
  end
  let(:options) { {} }

  describe '#initialize' do
    context 'when building a request' do
      it 'creates a request object' do
        expect(create).to be_a(described_class)
      end

      it 'sets the default value for the entries format if not specified' do
        expect(create.dictionaries.first[:entries_format]).to eq('tsv')
      end

      it 'serializes array entries into a tsv string' do
        expect(create.dictionaries.first[:entries]).to eq("Hello\tHola\nWorld\tMundo")
      end
    end
  end
end
