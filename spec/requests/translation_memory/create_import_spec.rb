# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::TranslationMemory::CreateImport do
  subject(:translation_memory_create_import) do
    described_class.new(api, file_name, content_length, options)
  end

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:file_name) { 'legal.tmx' }
  let(:content_length) { 128 }
  let(:options) { {} }

  describe '#initialize' do
    context 'when building a request' do
      it 'creates a request object' do
        expect(translation_memory_create_import).to be_a(described_class)
      end
    end
  end

  describe '#to_s' do
    context 'when building a request' do
      it 'posts to the import endpoint below the v3 prefix' do
        expect(translation_memory_create_import.to_s)
          .to eq('POST /v3/translation_memories/import')
      end
    end
  end

  describe '#details' do
    context 'when only the required parameters are given' do
      it 'declares the source file without the optional fields' do
        expect(translation_memory_create_import.details).to include('legal.tmx', '128')
        expect(translation_memory_create_import.details).not_to include('content_type')
        expect(translation_memory_create_import.details).not_to include('parameters')
      end
    end

    context 'when the optional parameters are given' do
      let(:options) { { content_type: 'text/xml', display_name: 'Legal' } }

      it 'declares the content type and the display name' do
        expect(translation_memory_create_import.details)
          .to include('content_type', 'text/xml')
        expect(translation_memory_create_import.details)
          .to include('parameters', 'display_name', 'Legal')
      end
    end
  end
end
