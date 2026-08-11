# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::TranslationMemory::Destroy do
  subject(:translation_memory_destroy) { described_class.new(api, id, options) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:id) { 'a74d88fb-ed2a-4943-a664-a4512398b994' }
  let(:options) { {} }

  describe '#initialize' do
    context 'when building a request' do
      it 'creates a request object' do
        expect(translation_memory_destroy).to be_a(described_class)
      end
    end
  end

  describe '#to_s' do
    context 'when building a request' do
      it 'deletes the translation memory below the v3 prefix' do
        expect(translation_memory_destroy.to_s).to eq("DELETE /v3/translation_memories/#{id}")
      end
    end
  end
end
