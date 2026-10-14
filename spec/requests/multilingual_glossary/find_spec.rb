# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::MultilingualGlossary::Find do
  subject(:find) { described_class.new(api, id) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:id) { '9ab5dac2-b7b2-4b4a-808a-e8e305df5ecb' }

  describe '#initialize' do
    it 'creates a request object' do
      expect(find).to be_a(described_class)
    end
  end

  describe '#to_s' do
    it 'targets the v3 glossary endpoint with a GET' do
      expect(find.to_s).to eq("GET /v3/glossaries/#{id}")
    end
  end
end
