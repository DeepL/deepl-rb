# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Resources::TranslationMemoryJob do
  subject(:job) { described_class.new(response, nil, nil) }

  let(:response) do
    {
      'job_id' => '5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d',
      'product' => 'translation_memory',
      'operation' => 'import',
      'creation_time' => '2026-01-01T00:00:00Z',
      'updated_time' => '2026-01-02T00:00:00Z',
      'source_file' => { 'content_type' => 'application/xml', 'content_length' => 128 },
      'parameters' => { 'display_name' => 'Legal' },
      'results' => [
        { 'status' => 'completed', 'translation_memory_id' => 'tm-1',
          'skipped_segment_count' => 2 }
      ]
    }
  end

  describe '#initialize' do
    it 'creates a resource' do
      expect(job).to be_a(described_class)
    end

    it 'assigns the job level attributes' do
      expect(job.job_id).to eq('5b1a0a52-1f3b-4b7f-9f6b-9d4d3f5b6c7d')
      expect(job.product).to eq('translation_memory')
      expect(job.operation).to eq('import')
      expect(job.creation_time).to eq(Time.parse('2026-01-01T00:00:00Z'))
      expect(job.updated_time).to eq(Time.parse('2026-01-02T00:00:00Z'))
      expect(job.display_name).to eq('Legal')
      expect(job.source_content_type).to eq('application/xml')
      expect(job.source_content_length).to eq(128)
    end

    it 'maps the single result and delegates the status helpers to it' do
      expect(job.result).to be_a(DeepL::Resources::TranslationMemoryJobResult)
      expect(job.status).to eq('completed')
      expect(job.finished?).to be(true)
      expect(job.awaiting_input?).to be(false)
      expect(job.error?).to be(false)
      expect(job.result.translation_memory_id).to eq('tm-1')
      expect(job.result.skipped_segment_count).to eq(2)
    end
  end

  context 'when the job is awaiting its file upload' do
    let(:response) do
      { 'job_id' => 'job-1', 'operation' => 'import',
        'results' => [{ 'status' => 'awaiting_input',
                        'status_metadata' => { 'required_action' => 'Waiting for upload' } }] }
    end

    it 'exposes the required action and does not report the job as finished' do
      expect(job.awaiting_input?).to be(true)
      expect(job.finished?).to be(false)
      expect(job.result.required_action).to eq('Waiting for upload')
    end
  end

  context 'when the export job completed' do
    let(:response) do
      { 'job_id' => 'job-2', 'operation' => 'export',
        'parameters' => { 'translation_memory_id' => 'tm-1' },
        'results' => [{ 'status' => 'completed', 'download_url' => 'https://example.com/tmx',
                        'expires_at' => '2026-01-03T00:00:00Z' }] }
    end

    it 'exposes the download URL and its expiry' do
      expect(job.translation_memory_id).to eq('tm-1')
      expect(job.result.download_url).to eq('https://example.com/tmx')
      expect(job.result.expires_at).to eq(Time.parse('2026-01-03T00:00:00Z'))
      expect(job.to_s).to eq('TranslationMemoryJob: export - ID: job-2 - Status: completed')
    end
  end

  context 'when the job failed' do
    let(:response) do
      { 'job_id' => 'job-3', 'operation' => 'import',
        'results' => [{ 'status' => 'failed', 'error' => { 'message' => 'Invalid TMX' } }] }
    end

    it 'reports the error and treats the job as finished' do
      expect(job.error?).to be(true)
      expect(job.finished?).to be(true)
      expect(job.error_message).to eq('Invalid TMX')
    end
  end

  context 'when the API returned no result' do
    let(:response) { { 'job_id' => 'job-4', 'operation' => 'import' } }

    it 'reports neither a status nor an error' do
      expect(job.result).to be_nil
      expect(job.status).to be_nil
      expect(job.finished?).to be(false)
      expect(job.awaiting_input?).to be(false)
      expect(job.error?).to be(false)
      expect(job.error_message).to be_nil
    end
  end
end
