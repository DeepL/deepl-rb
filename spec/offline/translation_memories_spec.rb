# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::TranslationMemoryApi do
  let(:memories) { DeepL.translation_memories }
  let(:upload_url) { 'https://storage.example.test/upload?sig=abc' }
  let(:download_url) { 'https://storage.example.test/download?sig=def' }
  let(:memory_json) do
    { translation_memory_id: 'tm-1', name: 'memory', source_language: 'de',
      target_languages: %w[en fr], segment_count: 3, creation_time: '2026-01-02T03:04:05Z',
      updated_time: '2026-02-03T04:05:06Z' }
  end

  def job_json(status, operation: 'import', **result)
    { job_id: 'j-1', product: 'translation_memory', operation: operation,
      results: [{ status: status }.merge(result)] }
  end

  def job_resource(status, **result)
    json = job_json(status, operation: 'export', **result).to_json
    DeepL::Resources::TranslationMemoryJob.new(JSON.parse(json), nil, nil)
  end

  def stub_job(*replies)
    stub_request(:get, url('/v3/translation_memories/jobs/j-1')).with(headers: json_headers)
                                                                .to_return(*replies)
  end

  def no_authorization
    ->(request) { !request.headers.key?('Authorization') }
  end

  describe '#list' do
    it 'sends a GET without a query by default and parses the timestamps' do
      stub_request(:get, url('/v3/translation_memories'))
        .with(headers: json_headers).to_return(reply(translation_memories: [memory_json]))

      memory = memories.list.first

      expect([memory.creation_time, memory.updated_time])
        .to eq([Time.utc(2026, 1, 2, 3, 4, 5), Time.utc(2026, 2, 3, 4, 5, 6)])
    end

    it 'sends page and page_size in the query' do
      stub_request(:get, url('/v3/translation_memories?page=1&page_size=20'))
        .to_return(reply(translation_memories: []))

      memories.list(page: 1, page_size: 20)
    end
  end

  describe '#find and #destroy' do
    it 'accept an ID or a translation memory object' do
      object = DeepL::Resources::TranslationMemory.new({ 'translation_memory_id' => 'tm-1' },
                                                       nil, nil)
      stub_request(:get, url('/v3/translation_memories/tm-1'))
        .with(headers: json_headers).to_return(reply(memory_json))
      stub_request(:delete, url('/v3/translation_memories/tm-1'))
        .with(headers: json_headers).to_return(status: 204)

      memories.find('tm-1')
      memories.find(object)

      expect([memories.destroy('tm-1'), memories.destroy(object)]).to eq(%w[tm-1 tm-1])
    end

    ['', nil].each do |id|
      it "raise Error for the ID #{id.inspect} without sending a request" do
        expect { memories.find(id) }.to raise_error(DeepL::Exceptions::Error, /must not be empty/)
        expect { memories.destroy(id) }
          .to raise_error(DeepL::Exceptions::Error, /must not be empty/)
      end
    end
  end

  describe '#segments' do
    let(:segments_json) do
      { segment_count: 7, next_page_cursor: 'c-2',
        segments: [{ source_segment_id: 'a', source_text: 'Haus',
                     targets: [{ target_segment_id: 'b', target_language: 'en',
                                 target_text: 'house', creation_time: '2026-01-02T03:04:05Z' }] }] }
    end

    it 'sends the paging and filter options in the query' do
      query = 'page_size=5&page_cursor=c-1&filter_text=a%20b&filter_case_sensitive=true'
      stub_request(:get, url("/v3/translation_memories/tm-1/segments?#{query}"))
        .with(headers: json_headers).to_return(reply(segments_json))

      memories.segments('tm-1', page_size: 5, page_cursor: 'c-1', filter_text: 'a b',
                                filter_case_sensitive: true)
    end

    it 'parses the timestamp of a target and the next page' do
      stub_request(:get, url('/v3/translation_memories/tm-1/segments'))
        .to_return(reply(segments_json))

      page = memories.segments('tm-1')
      segment = page.segments.first
      target = segment.targets.first

      expect([page.next_page?, target.creation_time]).to eq([true, Time.utc(2026, 1, 2, 3, 4, 5)])
    end

    it 'reports no next page when there is no cursor' do
      stub_request(:get, url('/v3/translation_memories/tm-1/segments'))
        .to_return(reply(segment_count: 0, segments: []))

      expect(memories.segments('tm-1').next_page?).to be(false)
    end
  end

  describe '#create_import' do
    it 'sends the source file description' do
      stub_request(:post, url('/v3/translation_memories/import'))
        .with(body: { source_file: { file_name: 'a.tmx', content_length: 12 } },
              headers: json_headers)
        .to_return(reply({ job_id: 'j-1', upload_url: upload_url }, 201))

      memories.create_import('a.tmx', 12)
    end

    it 'sends the content type and display name when given, and parses the expiry' do
      stub_request(:post, url('/v3/translation_memories/import'))
        .with(body: { source_file: { file_name: 'a.tmx', content_length: 12,
                                     content_type: 'application/x-tmx' },
                      parameters: { display_name: 'My memory' } })
        .to_return(reply({ job_id: 'j-1', upload_url: upload_url,
                           expires_at: '2026-03-04T05:06:07Z' }, 201))

      created = memories.create_import('a.tmx', 12, content_type: 'application/x-tmx',
                                                    display_name: 'My memory')

      expect(created.expires_at).to eq(Time.utc(2026, 3, 4, 5, 6, 7))
    end
  end

  describe '#upload_file' do
    it 'sends the content as the PUT body without credentials' do
      stub_request(:put, upload_url)
        .with(body: Fixtures::EXAMPLE_TMX, headers: { 'Content-Type' => 'application/xml' },
              &no_authorization).to_return(status: 200)

      memories.upload_file(upload_url, Fixtures::EXAMPLE_TMX)
    end

    it 'takes the URL from an import and sends the given content type and bytes' do
      created = DeepL::Resources::TranslationMemoryImport.new({ 'upload_url' => upload_url },
                                                              nil, nil)
      stub_request(:put, upload_url)
        .with(body: Fixtures::BINARY_CONTENT, headers: { 'Content-Type' => 'text/xml' },
              &no_authorization).to_return(status: 200)

      memories.upload_file(created, Fixtures::BINARY_CONTENT, content_type: 'text/xml')
    end
  end

  describe '#find_job' do
    it 'parses the job parameters, status and result' do
      stub_job(reply(job_json('completed', translation_memory_id: 'tm-1', skipped_segment_count: 2)
                       .merge(parameters: { translation_memory_id: 'tm-1',
                                            display_name: 'memory' })))

      job = memories.find_job('j-1')

      expect([job.status, job.finished?, job.error?, job.translation_memory_id, job.display_name])
        .to eq(['completed', true, false, 'tm-1', 'memory'])
    end

    {
      'awaiting_input' => [false, true, false],
      'processing' => [false, false, false],
      'completed' => [true, false, false],
      'downloaded' => [true, false, false],
      'failed' => [true, false, true],
      'expired' => [true, false, true]
    }.each do |status, flags|
      it "parses the #{status} status as finished, awaiting input, error: #{flags.inspect}" do
        stub_job(reply(job_json(status)))

        job = memories.find_job('j-1')

        expect([job.finished?, job.awaiting_input?, job.error?]).to eq(flags)
      end
    end

    it 'rejects an empty job ID without sending a request' do
      expect { memories.find_job('') }.to raise_error(DeepL::Exceptions::Error, /must not be empty/)
    end
  end

  describe '#wait_until_job_done' do
    it 'returns a finished job without sleeping' do
      stub = stub_job(reply(job_json('completed')))

      expect(memories.wait_until_job_done('j-1').status).to eq('completed')
      expect(stub).to have_been_requested.once
    end

    it 'polls until the job is completed' do
      stub = stub_job(reply(job_json('awaiting_input')), reply(job_json('completed')))

      job = memories.wait_until_job_done(DeepL::Resources::TranslationMemoryJob.new(
                                           { 'job_id' => 'j-1' }, nil, nil
                                         ))

      expect(job.status).to eq('completed')
      expect(stub).to have_been_requested.twice
    end

    %w[failed expired].each do |status|
      it "raises Error with the API message when the job is #{status}" do
        stub_job(reply(job_json(status, error: { message: 'bad file' })))

        expect { memories.wait_until_job_done('j-1') }
          .to raise_error(DeepL::Exceptions::Error, /import: bad file/)
      end
    end

    it 'raises Error with the status when the job has no error message' do
      stub_job(reply(job_json('failed')))

      expect do
        memories.wait_until_job_done('j-1')
      end.to raise_error(DeepL::Exceptions::Error, /: failed/)
    end

    it 'raises Error when timeout_s is exceeded while the job is not finished' do
      stub_job(reply(job_json('processing')))

      expect { memories.wait_until_job_done('j-1', timeout_s: 0) }
        .to raise_error(DeepL::Exceptions::Error, /timeout of 0s exceeded/)
    end
  end

  describe '#create_export' do
    it 'sends a POST with an empty body and parses a new export' do
      stub_request(:post, url('/v3/translation_memories/tm-1/export'))
        .with(body: '{}', headers: json_headers)
        .to_return(reply({ job_id: 'j-1', parameters: { translation_memory_id: 'tm-1' } }, 202))

      export = memories.create_export('tm-1')

      expect([export.translation_memory_id, export.reused_existing?]).to eq(['tm-1', false])
    end

    it 'reports an export that the API reused' do
      stub_request(:post, url('/v3/translation_memories/tm-1/export'))
        .to_return(reply({ job_id: 'j-1' }, 200))

      expect(memories.create_export('tm-1').reused_existing?).to be(true)
    end
  end

  describe '#download_export' do
    let(:output) { File.join(temp_dir, 'export.tmx') }

    include_context 'with a temporary directory'

    it 'writes the download to the file byte for byte, without credentials' do
      stub_request(:get, download_url).with(&no_authorization)
                                      .to_return(status: 200, body: Fixtures::BINARY_CONTENT)

      memories.download_export(download_url, output)

      expect(File.binread(output)).to eq(Fixtures::BINARY_CONTENT)
    end

    it 'takes the URL from a finished export job' do
      stub_request(:get, download_url).to_return(status: 200, body: 'tmx')

      memories.download_export(job_resource('completed', download_url: download_url), output)

      expect(File.read(output)).to eq('tmx')
    end

    it 'raises Error for a job without a download URL' do
      expect { memories.download_export(job_resource('processing'), output) }
        .to raise_error(DeepL::Exceptions::Error, /no download URL/)
    end
  end

  describe 'convenience methods' do
    include_context 'with a temporary directory'

    it 'imports a file: creates the import, uploads the bytes and waits for the job' do # rubocop:disable RSpec/ExampleLength
      path = File.join(temp_dir, 'memory.tmx')
      File.write(path, Fixtures::EXAMPLE_TMX)
      stub_request(:post, url('/v3/translation_memories/import'))
        .with(body: { source_file: { file_name: 'memory.tmx',
                                     content_length: Fixtures::EXAMPLE_TMX.bytesize },
                      parameters: { display_name: 'imported' } })
        .to_return(reply({ job_id: 'j-1', upload_url: upload_url }, 201))
      stub_request(:put, upload_url).with(body: Fixtures::EXAMPLE_TMX).to_return(status: 200)
      stub_job(reply(job_json('completed', translation_memory_id: 'tm-1')))

      job = memories.import_from_filepath(path, display_name: 'imported')

      expect(job.finished?).to be(true)
    end

    it 'raises Error for a missing import file without sending a request' do
      expect { memories.import_from_filepath(File.join(temp_dir, 'missing.tmx')) }
        .to raise_error(DeepL::Exceptions::Error, /No file found/)
    end

    it 'exports to a file: creates the export, waits for the job and downloads the result' do
      output = File.join(temp_dir, 'export.tmx')
      stub_request(:post, url('/v3/translation_memories/tm-1/export'))
        .to_return(reply({ job_id: 'j-1' }, 202))
      stub_job(reply(job_json('completed', operation: 'export', download_url: download_url)))
      stub_request(:get, download_url).to_return(status: 200, body: 'tmx')

      job = memories.export_to_filepath('tm-1', output)

      expect([File.read(output), job.status]).to eq(%w[tmx completed])
    end
  end
end
