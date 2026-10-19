# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

# The import appears as a translation memory only after about a minute, and a run killed in that
# window leaves one memory behind.
describe 'DeepL.translation_memories' do
  include_context 'with a temporary directory'

  let(:job_timeout_s) { 120 }

  it 'sends the translation memory requests: import, upload, get, list, segments, export, delete' do
    memories = DeepL.translation_memories
    name = unique_name('translation-memory')
    memory_id = nil
    begin
      created = memories.create_import('example.tmx', Fixtures::EXAMPLE_TMX.bytesize,
                                       display_name: name)
      expect([created.job_id.class, created.upload_url.class]).to eq([String, String])

      memories.upload_file(created, Fixtures::EXAMPLE_TMX)
      import_job = memories.wait_until_job_done(created.job_id, timeout_s: job_timeout_s)
      memory_id = import_job.result.translation_memory_id
      expect([import_job.operation, import_job.status, memory_id.class])
        .to eq(['import', 'completed', String])

      fetched = memories.find(memory_id)
      expect([fetched.translation_memory_id, fetched.name]).to eq([memory_id, name])
      expect(found_on_any_page?(memory_id) do |page|
        memories.list(page: page, page_size: 100).map(&:translation_memory_id)
      end).to be(true)

      segments = memories.segments(memory_id)
      expect(segments.segments).not_to be_empty
      expect(segments.segments.first.source_segment_id).to be_a(String)

      exported = memories.create_export(memory_id)
      export_job = memories.wait_until_job_done(exported.job_id, timeout_s: job_timeout_s)
      output = File.join(temp_dir, 'export.tmx')
      memories.download_export(export_job, output)
      expect(File.read(output)).to include('<tmx')
    ensure
      delete_quietly { memories.destroy(memory_id) } unless memory_id.nil?
    end
  end
end
