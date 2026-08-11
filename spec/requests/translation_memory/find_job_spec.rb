# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::TranslationMemory::FindJob do
  subject(:translation_memory_find_job) { described_class.new(api, job_id, options) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:job_id) { '5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d' }
  let(:options) { {} }

  describe '#initialize' do
    context 'when building a request' do
      it 'creates a request object' do
        expect(translation_memory_find_job).to be_a(described_class)
      end
    end
  end

  describe '#to_s' do
    context 'when building a request' do
      it 'requests the job below the v3 prefix' do
        expect(translation_memory_find_job.to_s)
          .to eq("GET /v3/translation_memories/jobs/#{job_id}")
      end
    end
  end
end
