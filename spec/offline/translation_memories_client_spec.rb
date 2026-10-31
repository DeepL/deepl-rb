# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL::Client translation memories' do
  let(:client) { DeepL::Client.new('client-key', server_url: 'https://client.example.test') }
  let(:upload_url) { 'https://storage.example.test/upload?sig=abc' }
  let(:download_url) { 'https://storage.example.test/download?sig=def' }
  let(:memory) do
    DeepL::Resources::TranslationMemory.new({ 'translation_memory_id' => 'tm-1' }, nil, nil)
  end
  let(:memory_json) do
    { translation_memory_id: 'tm-1', name: 'memory', source_language: 'de',
      target_languages: ['en'], segment_count: 3 }
  end

  def url(path)
    "https://client.example.test#{path}"
  end

  def json_headers
    { 'Authorization' => 'DeepL-Auth-Key client-key', 'Content-Type' => 'application/json' }
  end

  def job_json(status, **result)
    { job_id: 'j-1', product: 'translation_memory', operation: 'export',
      results: [{ status: status }.merge(result)] }
  end

  def stub_job(*replies)
    stub_request(:get, url('/v3/translation_memories/jobs/j-1')).with(headers: json_headers)
                                                                .to_return(*replies)
  end

  describe '#list_translation_memories' do
    it 'sends no query by default' do
      stub_request(:get, url('/v3/translation_memories')).with(headers: json_headers)
                                                         .to_return(reply(translation_memories:
                                                                            [memory_json]))

      expect(client.list_translation_memories.map(&:translation_memory_id)).to eq(['tm-1'])
    end

    it 'sends page and page_size in the query' do
      stub_request(:get, url('/v3/translation_memories?page=1&page_size=5'))
        .to_return(reply(translation_memories: []))

      client.list_translation_memories(page: 1, page_size: 5)
    end
  end

  describe 'per-memory operations' do
    it 'sends get and delete for an ID or a TranslationMemory' do
      stub_request(:get, url('/v3/translation_memories/tm-1')).with(headers: json_headers)
                                                              .to_return(reply(memory_json))
      stub_request(:delete, url('/v3/translation_memories/tm-1')).to_return(status: 204)

      expect(client.get_translation_memory(memory).name).to eq('memory')
      expect(client.delete_translation_memory('tm-1')).to be_nil
    end

    it 'sends the segment options in the query' do
      query = 'page_size=5&page_cursor=c-1&filter_text=a%20b&filter_case_sensitive=false'
      stub_request(:get, url("/v3/translation_memories/tm-1/segments?#{query}"))
        .with(headers: json_headers).to_return(reply(segment_count: 1, segments: []))

      page = client.list_translation_memory_segments(memory, page_size: 5, page_cursor: 'c-1',
                                                             filter_text: 'a b',
                                                             filter_case_sensitive: false)

      expect(page.segment_count).to eq(1)
    end
  end

  describe 'import' do
    include_context 'with a temporary directory'

    it 'sends the import job with the content type, display name and extra body parameters' do # rubocop:disable RSpec/ExampleLength
      stub_request(:post, url('/v3/translation_memories/import'))
        .with(body: { source_file: { file_name: 'a.tmx', content_length: 12,
                                     content_type: 'text/xml' },
                      parameters: { display_name: 'Legal' }, extra: true },
              headers: json_headers)
        .to_return(reply({ job_id: 'j-1', upload_url: upload_url }, 201))

      created = client.create_translation_memory_import('a.tmx', 12, content_type: 'text/xml',
                                                                     display_name: 'Legal',
                                                                     extra_body_parameters:
                                                                       { extra: true })

      expect(created.upload_url).to eq(upload_url)
    end

    it 'uploads the file without credentials, by default as application/xml' do
      no_authorization = ->(request) { !request.headers.key?('Authorization') }
      stub_request(:put, upload_url)
        .with(body: 'tmx', headers: { 'Content-Type' => 'application/xml' }, &no_authorization)
        .to_return(status: 200)
      stub_request(:put, upload_url).with(headers: { 'Content-Type' => 'text/xml' })
                                    .to_return(status: 200)

      expect(client.upload_translation_memory_file(upload_url, 'tmx')).to be_nil
      client.upload_translation_memory_file(upload_url, 'tmx', content_type: 'text/xml')
    end

    it 'imports a file: creates the job, uploads with the content type and waits' do # rubocop:disable RSpec/ExampleLength
      path = File.join(temp_dir, 'memory.tmx')
      File.write(path, 'tmx')
      stub_request(:post, url('/v3/translation_memories/import'))
        .with(body: { source_file: { file_name: 'memory.tmx', content_length: 3,
                                     content_type: 'text/xml' },
                      parameters: { display_name: 'Legal' }, extra: 'x' })
        .to_return(reply({ job_id: 'j-1', upload_url: upload_url }, 201))
      stub_request(:put, upload_url).with(body: 'tmx', headers: { 'Content-Type' => 'text/xml' })
                                    .to_return(status: 200)
      stub_job(reply(job_json('completed', translation_memory_id: 'tm-2')))

      job = client.import_translation_memory_from_filepath(
        path, display_name: 'Legal', content_type: 'text/xml', timeout_s: 10,
              extra_body_parameters: { extra: 'x' }
      )

      expect([job.done?, job.result.translation_memory_id]).to eq([true, 'tm-2'])
    end

    it 'raises ArgumentError for a missing import file without sending a request' do
      expect { client.import_translation_memory_from_filepath(File.join(temp_dir, 'missing.tmx')) }
        .to raise_error(ArgumentError, /No file found/)
    end

    it 'raises Error with the cause for an unreadable import file without sending a request' do
      expect { client.import_translation_memory_from_filepath(temp_dir) }
        .to raise_error(DeepL::Exceptions::Error, /Could not read/) { |error|
          expect(error.cause).to be_a(Errno::EISDIR)
        }
    end
  end

  describe 'export' do
    include_context 'with a temporary directory'

    let(:output) { File.join(temp_dir, 'export.tmx') }

    it 'creates the export, gets the job and downloads the file' do
      stub_request(:post, url('/v3/translation_memories/tm-1/export'))
        .with(body: '{}', headers: json_headers)
        .to_return(reply({ job_id: 'j-1', parameters: { translation_memory_id: 'tm-1' } }, 202))
      stub_job(reply(job_json('completed', download_url: download_url)))
      stub_request(:get, download_url).to_return(status: 200, body: 'tmx')

      export = client.create_translation_memory_export(memory)
      job = client.get_translation_memory_job(export.job_id)

      expect([export.translation_memory_id, export.reused_existing?]).to eq(['tm-1', false])
      expect(client.download_translation_memory_export(job, output)).to be_nil
      expect(File.read(output)).to eq('tmx')
    end

    it 'exports to a file: creates the export, waits and downloads' do
      stub_request(:post, url('/v3/translation_memories/tm-1/export'))
        .to_return(reply({ job_id: 'j-1' }, 200))
      stub_job(reply(job_json('completed', download_url: download_url)))
      stub_request(:get, download_url).to_return(status: 200, body: 'tmx')

      job = client.export_translation_memory_to_filepath('tm-1', output, timeout_s: 10)

      expect([job.status, File.read(output)]).to eq(%w[completed tmx])
    end

    it 'raises Error for a missing output directory before creating the export job' do
      missing = File.join(temp_dir, 'missing', 'x.tmx')

      expect { client.export_translation_memory_to_filepath('tm-1', missing) }
        .to raise_error(DeepL::Exceptions::Error, /does not exist/)
    end

    it 'raises Error with the cause when the file cannot be written' do
      stub_request(:get, download_url).to_return(status: 200, body: 'tmx')

      expect do
        client.download_translation_memory_export(download_url,
                                                  File.join(temp_dir, 'missing', 'x.tmx'))
      end.to raise_error(DeepL::Exceptions::Error, /Could not write/) { |error|
        expect(error.cause).to be_a(Errno::ENOENT)
      }
    end
  end

  describe '#wait_until_translation_memory_job_done' do
    it 'returns the completed job for an ID or a job' do
      stub = stub_job(reply(job_json('completed')))
      job = DeepL::Resources::TranslationMemoryJob.new({ 'job_id' => 'j-1' }, nil, nil)

      expect(client.wait_until_translation_memory_job_done(job).status).to eq('completed')
      expect(stub).to have_been_requested.once
    end

    it 'raises Error with the API message when the job failed' do
      stub_job(reply(job_json('failed', error: { message: 'bad file' })))

      expect { client.wait_until_translation_memory_job_done('j-1') }
        .to raise_error(DeepL::Exceptions::Error, /bad file/)
    end

    it 'raises Error when timeout_s expires' do
      stub_job(reply(job_json('processing')))

      expect { client.wait_until_translation_memory_job_done('j-1', timeout_s: 0) }
        .to raise_error(DeepL::Exceptions::Error, /timeout of 0s exceeded/)
    end
  end

  describe 'storage connection' do
    it 'uses the proxy of the client for the pre-signed URLs' do
      client = DeepL::Client.new('client-key', server_url: 'https://client.example.test',
                                               proxy: 'http://proxy.example.test:8080')
      stub_request(:put, upload_url).to_return(status: 200)

      expect(Net::HTTP).to receive(:new)
        .with('storage.example.test', 443, 'proxy.example.test', 8080, nil, nil)
        .and_call_original

      client.upload_translation_memory_file(upload_url, 'tmx')
    end

    it 'applies the timeouts and SSL verification of the http_client_options' do # rubocop:disable RSpec/ExampleLength
      options = DeepL::HTTPClientOptions.new({}, nil, enable_ssl_verification: false,
                                                      read_timeout: 33)
      client = DeepL::Client.new('client-key', server_url: 'https://client.example.test',
                                               http_client_options: options)
      connections = []
      allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *args|
        original.call(*args).tap { |connection| connections << connection }
      end
      stub_request(:get, download_url).to_return(status: 200, body: 'tmx')

      client.download_translation_memory_export(download_url, File::NULL)

      expect(connections.last)
        .to have_attributes(address: 'storage.example.test', read_timeout: 33,
                            verify_mode: OpenSSL::SSL::VERIFY_NONE)
    end
  end
end
