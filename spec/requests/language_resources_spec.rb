# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::LanguageResources do
  subject(:resources_obj) { described_class.new(api) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }

  describe '#initialize' do
    it 'targets the language resources endpoint' do
      expect(resources_obj.to_s).to eq('GET /v3/languages/resources')
    end
  end
end
