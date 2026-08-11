# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::TranslationMemory::Segments do
  subject(:translation_memory_segments) { described_class.new(api, id, options) }

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
        expect(translation_memory_segments).to be_a(described_class)
      end
    end
  end

  describe '#to_s' do
    context 'when no options are given' do
      it 'requests the segments below the v3 prefix without a query string' do
        expect(translation_memory_segments.to_s)
          .to eq("GET /v3/translation_memories/#{id}/segments")
      end
    end

    context 'when the supported options are given' do
      let(:options) { { page_size: 10, page_cursor: 'NQ', filter_case_sensitive: true } }

      it 'adds the options to the query string' do
        expect(translation_memory_segments.to_s)
          .to eq("GET /v3/translation_memories/#{id}/segments" \
                 '?page_size=10&page_cursor=NQ&filter_case_sensitive=true')
      end
    end

    context 'when the text filter contains characters that must be escaped' do
      let(:options) { { filter_text: 'a b+c' } }

      # A space must be percent-encoded in a URI query string; `+` only means a space in a form
      # body, and a literal `+` has to survive as %2B.
      it 'percent-encodes the spaces instead of writing them as a plus' do
        expect(translation_memory_segments.to_s)
          .to eq("GET /v3/translation_memories/#{id}/segments?filter_text=a%20b%2Bc")
      end
    end
  end
end
