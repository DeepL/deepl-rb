# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::TranslationMemory::DownloadExport do
  subject(:download_export) { described_class.new(api, download_url, output_path) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:download_url) { 'https://storage.example.com/download/tm?signature=abc' }
  let(:output_path) { '/tmp/export.tmx' }

  describe '#initialize' do
    context 'when building a request' do
      it 'creates a request object' do
        expect(download_export).to be_a(described_class)
      end
    end

    context 'when no download URL is given' do
      let(:download_url) { nil }

      it 'raises an error' do
        expect { download_export }.to raise_error(DeepL::Exceptions::Error, /must not be empty/)
      end
    end
  end

  describe '#to_s' do
    context 'when building a request' do
      it 'gets from the pre-signed storage URL' do
        expect(download_export.to_s).to eq('GET /download/tm?signature=abc')
      end
    end
  end

  describe '#details' do
    context 'when building a request' do
      # The download URL points outside of the DeepL API, so the auth key must not be sent there.
      it 'does not send the DeepL authorization header' do
        expect(download_export.details).not_to include('Authorization')
        expect(download_export.details).to include('User-Agent')
      end
    end
  end
end
