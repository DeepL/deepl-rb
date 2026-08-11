# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::TranslationMemory::UploadFile do
  subject(:upload_file) { described_class.new(api, upload_url, file_content) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:upload_url) { 'https://storage.example.com/upload/tm?signature=abc' }
  let(:file_content) { '<tmx version="1.4"/>' }

  describe '#initialize' do
    context 'when building a request' do
      it 'creates a request object' do
        expect(upload_file).to be_a(described_class)
        expect(upload_file.content_type).to eq(described_class::DEFAULT_CONTENT_TYPE)
      end
    end

    context 'when no upload URL is given' do
      let(:upload_url) { '' }

      it 'raises an error' do
        expect { upload_file }.to raise_error(DeepL::Exceptions::Error, /must not be empty/)
      end
    end
  end

  describe '#to_s' do
    context 'when building a request' do
      it 'puts to the pre-signed storage URL' do
        expect(upload_file.to_s).to eq('PUT /upload/tm?signature=abc')
      end
    end
  end

  describe '#details' do
    context 'when building a request' do
      # The upload URL points outside of the DeepL API, so the auth key must not be sent there.
      it 'does not send the DeepL authorization header' do
        expect(upload_file.details).not_to include('Authorization')
        expect(upload_file.details).to include('User-Agent')
      end
    end
  end
end
