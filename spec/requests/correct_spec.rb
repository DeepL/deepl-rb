# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::Correct do
  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:text) do
    'As Gregor Samsa awoke one morning from uneasy dreams he found himself transformed.'
  end
  let(:target_lang) { 'EN' }

  describe '#initialize' do
    context 'when passing additional headers' do
      it 'merges the headers into the request headers' do
        request = described_class.new(api, text, target_lang, {},
                                      { 'X-DeepL-Reporting-Tag' => 'my-tag' })
        expect(request.send(:headers)).to include('X-DeepL-Reporting-Tag' => 'my-tag')
      end

      it 'defaults to no additional headers' do
        request = described_class.new(api, text, target_lang)
        expect(request.send(:headers).keys).to contain_exactly('Authorization', 'User-Agent')
      end
    end

    context 'with invalid text' do
      it 'raises ArgumentError for an empty string' do
        expect { described_class.new(api, '') }.to raise_error(ArgumentError, /non-empty/)
      end

      it 'raises ArgumentError for an empty array' do
        expect { described_class.new(api, []) }.to raise_error(ArgumentError, /non-empty/)
      end

      it 'raises ArgumentError when an array contains an empty string' do
        expect { described_class.new(api, [text, '']) }.to raise_error(ArgumentError, /non-empty/)
      end
    end

    context 'with a target language applied' do
      it 'has the correct target language applied' do
        request = described_class.new(api, text, target_lang)
        expect(request.target_lang).to eq('EN')
      end
    end
  end
end
