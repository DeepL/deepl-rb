# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::TranslationMemoryApi, :mock_server_only do
  include_context 'with temp dir'

  let(:default_tm_id) { 'a74d88fb-ed2a-4943-a664-a4512398b994' }
  let(:tmx_file_path) { write_example_tmx(File.join(temp_dir, 'example.tmx')) }
  let(:translation_memories) { DeepL.translation_memories }

  describe '#translate_with_translation_memory' do
    it 'when performing a request with translation_memory_id' do
      source_lang = 'DE'
      target_lang = 'EN'
      text = 'Protonenstrahl'

      result = DeepL.translate(text, source_lang, target_lang,
                               { translation_memory: default_tm_id })
      expect(result).to be_a(DeepL::Resources::Text)
    end

    it 'when performing a request with translation_memory resource object' do
      source_lang = 'DE'
      target_lang = 'EN'
      text = 'Protonenstrahl'
      translation_memory = build_test_translation_memory

      result = DeepL.translate(text, source_lang, target_lang,
                               { translation_memory: translation_memory })
      expect(result).to be_a(DeepL::Resources::Text)
    end
  end

  describe '#list_translation_memories' do
    it 'when requesting a list of all translation memories' do
      translation_memories = DeepL.translation_memories.list
      expect(translation_memories).to be_an(Array)
      expect(translation_memories).not_to be_empty
      expect(translation_memories.first).to be_a(DeepL::Resources::TranslationMemory)
      expect(translation_memories.first.translation_memory_id).not_to be_nil
      expect(translation_memories.first.name).not_to be_nil
    end
  end

  describe '#find' do
    it 'when requesting a single translation memory by ID' do
      translation_memory = DeepL.translation_memories.find(default_tm_id)
      expect(translation_memory).to be_a(DeepL::Resources::TranslationMemory)
      expect(translation_memory.translation_memory_id).to eq(default_tm_id)
      expect(translation_memory.name).to eq('Default Translation Memory')
      expect(translation_memory.source_language).to eq('de')
      expect(translation_memory.target_languages).to eq(%w[en es fr])
      expect(translation_memory.segment_count).to eq(12)
    end

    it 'when requesting a single translation memory by resource object' do
      translation_memory = DeepL.translation_memories.find(build_test_translation_memory)
      expect(translation_memory.translation_memory_id).to eq(default_tm_id)
      expect(translation_memory.creation_time).to be_a(Time)
      expect(translation_memory.updated_time).to be_a(Time)
    end
  end

  describe '#segments' do
    it 'when requesting the segments of a translation memory' do
      page = DeepL.translation_memories.segments(default_tm_id)
      expect(page).to be_a(DeepL::Resources::TranslationMemorySegments)
      expect(page.segments.length).to eq(12)
      expect(page.segment_count).to eq(12)
      expect(page.next_page?).to be(false)
      expect(page.segments.first.source_text).to eq('Quelltext Nummer 0')
    end

    it 'when reading segment timestamps' do
      # The API does not return creation_time/updated_time on segments at all, and returns
      # last_used_time only for segments that have been used.
      page = DeepL.translation_memories.segments(default_tm_id)
      expect(page.segments.first.creation_time).to be_nil
      expect(page.segments.first.updated_time).to be_nil
      expect(page.segments.first.last_used_time).to be_a(Time)
      expect(page.segments[1].last_used_time).to be_nil
    end

    it 'when reading the target segments of a source segment' do
      page = DeepL.translation_memories.segments(default_tm_id, page_size: 1)
      segment = page.segments.first
      expect(segment.targets.map(&:target_language)).to eq(%w[en es fr])
      expect(segment.targets.first.target_text).to eq('Target text number 0 (de->en)')
      expect(segment.targets.first.target_segment_id).not_to be_nil
      expect(segment.targets.first.last_used_time).to be_a(Time)
    end

    it 'when paginating through the segments with the page cursor' do
      first_page = DeepL.translation_memories.segments(default_tm_id, page_size: 5)
      second_page = next_segments_page(first_page)
      last_page = next_segments_page(second_page)

      expect(first_page.segments.length).to eq(5)
      expect(first_page.next_page?).to be(true)
      expect(second_page.segments.first.source_text).to eq('Quelltext Nummer 5')
      expect(last_page.segments.length).to eq(2)
      expect(last_page.next_page?).to be(false)
    end

    it 'when filtering the segments by a text containing a space' do
      page = DeepL.translation_memories.segments(default_tm_id, filter_text: 'Nummer 1')
      expect(page.segments.map(&:source_text))
        .to eq(['Quelltext Nummer 1', 'Quelltext Nummer 10', 'Quelltext Nummer 11'])
      # segment_count is the number of segments stored in the translation memory, a text filter
      # does not reduce it.
      expect(page.segment_count).to eq(12)
    end

    it 'when filtering the segments case-sensitively' do
      page = DeepL.translation_memories.segments(default_tm_id, filter_text: 'quelltext',
                                                                filter_case_sensitive: true)
      expect(page.segments).to be_empty
      expect(page.segment_count).to eq(12)
    end
  end

  describe '#import_from_filepath' do
    it 'when importing a translation memory from a TMX file' do
      with_managed_translation_memory(tmx_file_path, display_name: 'Imported TM') do |job|
        expect(job).to be_a(DeepL::Resources::TranslationMemoryJob)
        expect(job.operation).to eq('import')
        expect(job.display_name).to eq('Imported TM')
        expect(job.status).to eq('completed')
        expect(job.finished?).to be(true)
        expect(job.result.translation_memory_id).not_to be_nil
        expect(job.result.skipped_segment_count).to eq(0)
      end
    end

    it 'when the imported translation memory can be retrieved afterwards' do
      with_managed_translation_memory(tmx_file_path) do |job|
        translation_memory = DeepL.translation_memories.find(job.result.translation_memory_id)
        expect(translation_memory.name).to eq('example.tmx')
        expect(translation_memory.source_language).to eq('de')
        expect(job.source_content_type).to eq('application/xml')
        expect(job.source_content_length).to eq(File.size(tmx_file_path))
      end
    end
  end

  describe '#create_import' do
    it 'when the import job is still awaiting the file upload' do
      created = DeepL.translation_memories.create_import('awaiting.tmx', 128,
                                                         display_name: 'Awaiting Upload')
      expect(created).to be_a(DeepL::Resources::TranslationMemoryImport)
      expect(created.upload_url).to start_with('http')
      expect(created.expires_at).to be_a(Time)

      job = DeepL.translation_memories.find_job(created.job_id)
      expect(job.awaiting_input?).to be(true)
      expect(job.status).to eq('awaiting_input')
      expect(job.result.required_action).not_to be_nil
    end

    # The API detects the upload asynchronously, so an uploaded job keeps reporting
    # `awaiting_input` for a while. The wait loop must poll through that status.
    it 'when waiting on an uploaded job it polls through the awaiting_input status' do
      created = create_uploaded_import(translation_memories, tmx_file_path, processing_polls: 1)
      polled_statuses = []
      allow(translation_memories).to receive(:find_job).and_wrap_original do |original, *args|
        original.call(*args).tap { |status| polled_statuses << status.status }
      end
      expect(translation_memories).to receive(:sleep).once

      job = translation_memories.wait_until_job_done(created.job_id)

      expect(polled_statuses).to eq(%w[awaiting_input completed])
      expect(job.status).to eq('completed')
      DeepL.translation_memories.destroy(job.result.translation_memory_id)
    end

    it 'when the file is never uploaded it waits until the timeout of the caller' do
      created = translation_memories.create_import('never-uploaded.tmx', 128)
      # Such a job does not finish on its own, only the timeout ends the wait.
      expect(translation_memories).not_to receive(:sleep)

      expect { translation_memories.wait_until_job_done(created.job_id, timeout_s: 0) }
        .to raise_error(DeepL::Exceptions::Error, /Manual timeout of 0s exceeded/)
    end
  end

  describe '#export_to_filepath' do
    let(:output_path) { File.join(temp_dir, 'export.tmx') }

    it 'when exporting a translation memory to a TMX file' do
      job = DeepL.translation_memories.export_to_filepath(default_tm_id, output_path)
      expect(job).to be_a(DeepL::Resources::TranslationMemoryJob)
      expect(job.operation).to eq('export')
      expect(job.status).to eq('completed')
      expect(job.result.download_url).to start_with('http')

      contents = File.read(output_path)
      expect(contents).to include('<tmx version="1.4">')
      expect(contents).to include('<seg>Quelltext Nummer 0</seg>')
      expect(contents).to include('<tuv xml:lang="en"><seg>Target text number 0 (de->en)</seg>')
    end

    it 'when re-exporting an unchanged translation memory it reuses the completed job' do
      job = DeepL.translation_memories.export_to_filepath(default_tm_id, output_path)
      reused = DeepL.translation_memories.create_export(default_tm_id)
      expect(reused).to be_a(DeepL::Resources::TranslationMemoryExport)
      expect(reused.reused_existing?).to be(true)
      expect(reused.job_id).to eq(job.job_id)
      expect(reused.translation_memory_id).to eq(default_tm_id)
    end
  end

  describe '#destroy' do
    it 'when deleting a translation memory it can no longer be found' do
      job = DeepL.translation_memories.import_from_filepath(tmx_file_path)
      translation_memory_id = job.result.translation_memory_id

      expect(DeepL.translation_memories.destroy(translation_memory_id))
        .to eq(translation_memory_id)
      expect { DeepL.translation_memories.find(translation_memory_id) }
        .to raise_error(DeepL::Exceptions::NotFound)
    end
  end

  def next_segments_page(page)
    DeepL.translation_memories.segments(default_tm_id, page_size: 5,
                                                       page_cursor: page.next_page_cursor)
  end

  def build_test_translation_memory
    tm_data = {
      'translation_memory_id' => 'a74d88fb-ed2a-4943-a664-a4512398b994',
      'name' => 'Default Translation Memory',
      'source_language' => 'DE',
      'target_languages' => %w[EN ES FR],
      'segment_count' => 3542
    }
    DeepL::Resources::TranslationMemory.new(tm_data, nil, nil)
  end
end
