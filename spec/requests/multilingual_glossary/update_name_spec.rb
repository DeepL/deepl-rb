# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::MultilingualGlossary::UpdateName do
  subject(:update_name) { described_class.new(api, id, name) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:id) { '9ab5dac2-b7b2-4b4a-808a-e8e305df5ecb' }
  let(:name) { 'Renamed Glossary' }

  describe '#initialize' do
    it 'creates a request object' do
      expect(update_name).to be_a(described_class)
    end
  end

  describe '#to_s' do
    it 'targets the v3 glossary endpoint with a PATCH' do
      expect(update_name.to_s).to eq("PATCH /v3/glossaries/#{id}")
    end
  end
end
