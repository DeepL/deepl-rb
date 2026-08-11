# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Resources::TranslationMemoryImport do
  subject(:translation_memory_import) do
    described_class.new({
                          'job_id' => '5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d',
                          'upload_url' => 'https://storage.example.com/upload',
                          'expires_at' => '2026-01-01T00:00:00Z'
                        }, nil, nil)
  end

  describe '#initialize' do
    it 'creates a resource' do
      expect(translation_memory_import).to be_a(described_class)
    end

    it 'assigns the attributes' do
      expect(translation_memory_import.job_id).to eq('5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d')
      expect(translation_memory_import.upload_url).to eq('https://storage.example.com/upload')
      expect(translation_memory_import.expires_at).to eq(Time.parse('2026-01-01T00:00:00Z'))
      expect(translation_memory_import.to_s)
        .to eq('TranslationMemoryImport: ID: 5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d')
    end
  end
end
