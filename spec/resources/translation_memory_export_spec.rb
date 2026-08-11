# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Resources::TranslationMemoryExport do
  subject(:translation_memory_export) { described_class.new(response, false, nil, nil) }

  let(:response) do
    {
      'job_id' => '5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d',
      'parameters' => { 'translation_memory_id' => 'a74d88fb-ed2a-4943-a664-a4512398b994' }
    }
  end

  describe '#initialize' do
    it 'creates a resource' do
      expect(translation_memory_export).to be_a(described_class)
    end

    it 'assigns the attributes of a newly created export' do
      expect(translation_memory_export.job_id).to eq('5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d')
      expect(translation_memory_export.translation_memory_id)
        .to eq('a74d88fb-ed2a-4943-a664-a4512398b994')
      expect(translation_memory_export.reused_existing?).to be(false)
    end

    context 'when the API reused a previously completed export' do
      subject(:translation_memory_export) { described_class.new(response, true, nil, nil) }

      it 'reports the export as reused' do
        expect(translation_memory_export.reused_existing?).to be(true)
      end
    end
  end
end
