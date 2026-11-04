# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'open3'
require_relative 'offline_helper'

describe 'document translation' do
  let(:handle) { DeepL::Resources::DocumentHandle.new('doc-1', 'key-1') }
  let(:upload_reply) { reply(document_id: 'doc-1', document_key: 'key-1') }
  let(:document_key_body) { { document_key: 'key-1' } }

  include_context 'with a temporary directory'

  def stub_upload
    stub_request(:post, url('/v2/document')).with(
      headers: { 'Authorization' => json_headers['Authorization'],
                 'Content-Type' => %r{\Amultipart/form-data} }
    )
  end

  # Net::HTTP writes multipart parts straight to the socket, so WebMock sees no request body.
  # The form fields are read from the argument of `set_form` instead.
  def capture_forms
    forms = []
    allow(Net::HTTP::Post).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap do |request|
        allow(request).to receive(:set_form).and_wrap_original do |set_form, form, *rest|
          forms << form
          set_form.call(form, *rest)
        end
      end
    end
    forms
  end

  # Uploads a text document with the given options and returns the form that was sent.
  def sent_form(filename = nil, **options)
    input, = create_text_document(temp_dir)
    stub_upload.to_return(upload_reply)
    forms = capture_forms
    api_client.translate_document_upload(input, 'EN', 'DE', filename: filename, **options)
    forms.first
  end

  def resource_options
    resources = DeepL::Resources
    memory = resources::TranslationMemory.new({ 'translation_memory_id' => 'tm-obj' }, nil, nil)
    glossary = resources::Glossary.new({ 'glossary_id' => 'g-obj' }, nil, nil)
    multilingual = resources::MultilingualGlossary.new({ 'glossary_id' => 'g-ml', 'name' => 'n' },
                                                       nil, nil)
    { style_rule: resources::StyleRule.new({ 'style_id' => 's-obj' }, nil, nil),
      style_profile: resources::StyleProfile.new({ 'style_profile_id' => 'sp-obj' }, nil, nil),
      translation_memory: memory, glossary_ids: [glossary, multilingual, 'g-str'] }
  end

  def form_fields(form)
    form.to_h.except('file')
  end

  def stub_status(*statuses)
    stub_request(:post, url('/v2/document/doc-1')).with(body: document_key_body,
                                                        headers: json_headers)
                                                  .to_return(*statuses)
  end

  def status_reply(status, extra = {})
    reply({ document_id: 'doc-1', status: status }.merge(extra))
  end

  describe 'DeepL::Client#translate_document_upload' do
    it 'sends a multipart POST with the credentials and the file, languages and filename' do
      input, = create_text_document(temp_dir)

      form = sent_form

      expect(form.assoc('file').last.path).to eq(input)
      expect(form_fields(form)).to eq('source_lang' => 'EN', 'target_lang' => 'DE',
                                      'filename' => 'example_document.txt')
    end

    it 'sends no source_lang when the source language is nil' do
      input, = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      forms = capture_forms

      api_client.translate_document_upload(input, nil, 'DE')

      expect(forms.first.assoc('file').last.path).to eq(input)
      expect(form_fields(forms.first)).to eq('target_lang' => 'DE',
                                             'filename' => 'example_document.txt')
    end

    it 'sends every option as its own field, serializing IDs, the threshold and glossary_ids' do
      form = sent_form('name.txt', formality: 'more', output_format: 'txt',
                                   glossary_ids: %w[g-1 g-2], style_rule: 's-1',
                                   style_profile: 'sp-1', translation_memory: 'tm-1',
                                   translation_memory_threshold: 80)

      expect(form_fields(form)).to eq(
        'source_lang' => 'EN', 'target_lang' => 'DE', 'filename' => 'name.txt',
        'formality' => 'more', 'output_format' => 'txt', 'glossary_ids' => 'g-1,g-2',
        'style_id' => 's-1', 'style_profile_id' => 'sp-1', 'translation_memory_id' => 'tm-1',
        'translation_memory_threshold' => '80'
      )
    end

    it 'sends enable_watermark as true or false, combined with output_format' do
      expect(form_fields(sent_form(enable_watermark: true, output_format: 'pdf')))
        .to include('enable_watermark' => 'true', 'output_format' => 'pdf')
      expect(form_fields(sent_form(enable_watermark: false)))
        .to include('enable_watermark' => 'false')
    end

    it 'does not send enable_watermark when it is not set' do
      expect(form_fields(sent_form)).not_to have_key('enable_watermark')
    end

    it 'does not send style_profile_id when it is not set' do
      expect(form_fields(sent_form(style_rule: 's-1'))).not_to have_key('style_profile_id')
    end

    it 'does not send style_profile_id when it is nil' do
      expect(form_fields(sent_form(style_profile: nil))).not_to have_key('style_profile_id')
    end

    it 'does not send style_id when style_rule is nil' do
      expect(form_fields(sent_form(style_rule: nil))).not_to have_key('style_id')
    end

    it 'takes the IDs of style rule, style profile, translation memory and glossary objects' do
      form = sent_form(**resource_options)

      expect(form_fields(form)).to include(
        'style_id' => 's-obj', 'style_profile_id' => 'sp-obj', 'translation_memory_id' => 'tm-obj',
        'glossary_ids' => 'g-obj,g-ml,g-str'
      )
    end

    it 'does not send translation_memory_id or the threshold when they are nil' do
      expect(form_fields(sent_form(translation_memory: nil, translation_memory_threshold: nil)))
        .to eq('source_lang' => 'EN', 'target_lang' => 'DE', 'filename' => 'example_document.txt')
    end

    it 'sends the glossary option, an ID or a glossary object, as glossary_id' do
      glossary = DeepL::Resources::MultilingualGlossary.new({ 'glossary_id' => 'g-ml',
                                                              'name' => 'n' }, nil, nil)
      expect(form_fields(sent_form(glossary: 'g-1'))).to include('glossary_id' => 'g-1')
      expect(form_fields(sent_form(glossary: glossary))).to include('glossary_id' => 'g-ml')
    end

    it 'lets extra_body_parameters add a field and override an existing one' do
      form = sent_form(formality: 'more', extra_body_parameters: { formality: 'less', beta: true })

      expect(form.count { |name, _| name == 'formality' }).to eq(1)
      expect(form_fields(form)).to include('formality' => 'less', 'beta' => 'true')
    end

    it 'raises ArgumentError for invalid glossary_ids without sending a request' do
      input, = create_text_document(temp_dir)

      expect { api_client.translate_document_upload(input, nil, 'DE', glossary_ids: ['g-1']) }
        .to raise_error(ArgumentError, /requires `source_lang`/)
      expect do
        api_client.translate_document_upload(input, 'EN', 'DE', glossary_ids: %w[1 2 3 4 5 6])
      end
        .to raise_error(ArgumentError, /maximum of 5/)
    end

    it 'raises ArgumentError for glossary without source_lang without sending a request' do
      input, = create_text_document(temp_dir)

      expect { api_client.translate_document_upload(input, nil, 'DE', glossary: 'g-1') }
        .to raise_error(ArgumentError, /requires `source_lang`/)
    end

    it 'raises ArgumentError for invalid languages or threshold without sending a request' do
      input, = create_text_document(temp_dir)

      expect { api_client.translate_document_upload(input, nil, '') }
        .to raise_error(ArgumentError, /target_lang/)
      expect { api_client.translate_document_upload(input, '', 'DE') }
        .to raise_error(ArgumentError, /source_lang/)
      expect do
        api_client.translate_document_upload(input, 'EN', 'DE', translation_memory_threshold: 80)
      end.to raise_error(ArgumentError, /requires `translation_memory`/)
    end

    it 'retries after a 429 reply' do
      input, = create_text_document(temp_dir)
      stub = stub_upload.to_return(reply({}, 429), upload_reply)

      api_client.translate_document_upload(input, 'EN', 'DE')

      expect(stub).to have_been_requested.twice
    end
  end

  describe 'DeepL::Client#translate_document_get_status' do
    it 'sends the document key and derives that a translating document is not finished' do
      stub_status(status_reply('translating', seconds_remaining: 3, billed_characters: 11,
                                              error_message: 'none'))

      status = api_client.translate_document_get_status(handle)

      expect(status.finished?).to be(false)
    end

    it 'parses done as done and error as failed' do
      stub_status(status_reply('done'), status_reply('error'))

      statuses = Array.new(2) { api_client.translate_document_get_status(handle) }

      expect(statuses.map { |s| [s.done?, s.error?, s.finished?] })
        .to eq([[true, false, true], [false, true, true]])
    end

    it 'derives ok? as not failed, also while queued or translating' do
      codes = DeepL::Constants::DocumentStatusCode
      stub_status(*[codes::QUEUED, codes::TRANSLATING, codes::DONE, codes::ERROR].map do |code|
        status_reply(code)
      end)

      statuses = Array.new(4) { api_client.translate_document_get_status(handle) }

      expect(statuses.map { |s| [s.status, s.ok?] }).to eq(
        [['queued', true], ['translating', true], ['done', true], ['error', false]]
      )
    end

    it 'URL-encodes the document ID in the path' do
      stub_request(:post, url('/v2/document/a%20b%2Fc')).to_return(status_reply('done'))

      handle = DeepL::Resources::DocumentHandle.new('a b/c', 'key-1', nil, nil)
      api_client.translate_document_get_status(handle)
    end
  end

  describe 'DeepL::Client#translate_document_download' do
    it 'raises SystemCallError for an existing file or a missing directory before the request' do
      existing = File.join(temp_dir, 'result.docx')
      File.write(existing, 'keep me')

      expect { api_client.translate_document_download(handle, existing) }
        .to raise_error(Errno::EEXIST)
      expect { api_client.translate_document_download(handle, File.join(temp_dir, 'no', 'x')) }
        .to raise_error(Errno::ENOENT)
      expect(File.read(existing)).to eq('keep me')
    end

    it 'writes the response body to the output file byte for byte' do
      output = File.join(temp_dir, 'result.docx')
      stub_request(:post, url('/v2/document/doc-1/result'))
        .with(body: document_key_body, headers: json_headers)
        .to_return(status: 200, body: Fixtures::BINARY_CONTENT)

      api_client.translate_document_download(handle, output)

      expect(File.binread(output)).to eq(Fixtures::BINARY_CONTENT)
    end

    it 'writes the bytes unchanged when Encoding.default_internal is set' do
      output = File.join(temp_dir, 'result.docx')
      stub_request(:post, url('/v2/document/doc-1/result'))
        .to_return(status: 200, body: Fixtures::BINARY_CONTENT)
      previous = Encoding.default_internal
      Encoding.default_internal = Encoding::UTF_8

      api_client.translate_document_download(handle, output)

      expect(File.binread(output)).to eq(Fixtures::BINARY_CONTENT)
    ensure
      Encoding.default_internal = previous
    end

    it 'URL-encodes the document ID in the path' do
      stub_request(:post, url('/v2/document/a%20b%2Fc/result')).to_return(status: 200, body: 'x')

      api_client.translate_document_download(
        DeepL::Resources::DocumentHandle.new('a b/c', 'key-1', nil, nil),
        File.join(temp_dir, 'result.txt')
      )
    end

    it 'raises DocumentNotReadyError, a ServerError, for a 503 reply' do
      stub = stub_request(:post, url('/v2/document/doc-1/result'))
             .to_return(reply({ message: 'not ready' }, 503))

      client = offline_client(max_retries: 0)
      output = File.join(temp_dir, 'result.txt')

      expect { client.translate_document_download(handle, output) }
        .to raise_error(DeepL::Exceptions::DocumentNotReadyError, /not ready/) { |e|
          expect([e, e.http_status_code]).to match([be_a(DeepL::Exceptions::ServerError), 503])
        }
      expect(stub).to have_been_requested.once
    end
  end

  describe DeepL::Resources::DocumentHandle, '#inspect' do
    it 'does not show the auth key' do
      api = DeepL::Client.new('sdktest-secret-key').send(:api)
      other = described_class.new('doc-1', 'key-1', nil, nil, api: api)

      expect(other.inspect).not_to include('sdktest-secret-key')
      expect(api.configuration.inspect).not_to include('sdktest-secret-key')
    end
  end

  describe 'DeepL::Client#translate_document' do
    it 'uploads, waits and writes the translated document' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('done'))
      stub_request(:post, url('/v2/document/doc-1/result'))
        .with(body: document_key_body).to_return(status: 200, body: 'Protonenstrahl')

      api_client.translate_document(input, output, 'EN', 'DE')

      expect(File.read(output)).to eq('Protonenstrahl')
    end

    it 'passes enable_watermark on to the upload' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('done'))
      stub_request(:post, url('/v2/document/doc-1/result')).to_return(status: 200, body: 'x')
      forms = capture_forms

      api_client.translate_document(input, output, 'EN', 'DE', enable_watermark: true)

      expect(form_fields(forms.first)).to include('enable_watermark' => 'true')
    end

    it 'raises DocumentTranslationError for a failed upload without other libraries loaded' do
      input, output_path = create_text_document(temp_dir)
      # Port 9 refuses the connection, so the failure is wrapped after cleaning up the output.
      script = <<~RUBY
        client = DeepL::Client.new('k', server_url: 'http://127.0.0.1:9', max_retries: 0)
        begin
          client.translate_document(#{input.inspect}, #{output_path.inspect}, 'EN', 'DE')
        rescue StandardError => e
          puts e.class
        end
      RUBY
      lib = File.expand_path('../../lib', __dir__)

      output, = Open3.capture3({ 'PATH' => ENV.fetch('PATH') }, RbConfig.ruby, '-I', lib, '-r',
                               'deepl', '-e', script, unsetenv_others: true)

      expect(output.strip).to eq('DeepL::Exceptions::DocumentTranslationError')
    end

    it 'raises DocumentTranslationError with the API message when the translation fails' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('error', error_message: 'Unsupported file'))

      expect { api_client.translate_document(input, output, 'EN', 'DE') }
        .to raise_error(DeepL::Exceptions::DocumentTranslationError, /Unsupported file/) { |e|
          expect(e.document_handle.document_id).to eq('doc-1')
        }
    end

    it 'raises DocumentTranslationError and leaves no output file when the download fails' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('done'))
      stub_request(:post,
                   url('/v2/document/doc-1/result')).to_return(reply({ message: 'gone' }, 404))

      expect { api_client.translate_document(input, output, 'EN', 'DE') }
        .to raise_error(DeepL::Exceptions::DocumentTranslationError, /gone/)
      expect(File.exist?(output)).to be(false)
    end
  end

  # The client has its own key and server, different from the module configuration, so a
  # request that falls back to module state hits no stub.
  describe 'DeepL::Client document translation' do
    let(:client) { DeepL::Client.new('client-key', server_url: 'https://client.example.test') }
    let(:poller) { DeepL::Utils::DocumentPoller }

    def url(path)
      "https://client.example.test#{path}"
    end

    def json_headers
      { 'Authorization' => 'DeepL-Auth-Key client-key', 'Content-Type' => 'application/json' }
    end

    def stub_download(body = 'Protonenstrahl')
      stub_request(:post, url('/v2/document/doc-1/result'))
        .with(body: document_key_body, headers: json_headers).to_return(status: 200, body: body)
    end

    describe '#translate_document_upload' do
      it 'sends the filename option as the filename field and returns the handle' do
        input, = create_text_document(temp_dir)
        stub_upload.to_return(upload_reply)
        forms = capture_forms

        result = client.translate_document_upload(input, 'EN', 'DE', filename: 'name.docx',
                                                                     formality: 'more')

        expect(form_fields(forms.first)).to eq('source_lang' => 'EN', 'target_lang' => 'DE',
                                               'filename' => 'name.docx', 'formality' => 'more')
        expect([result.document_id, result.document_key]).to eq(%w[doc-1 key-1])
      end

      it 'raises DocumentTranslationError for a missing output directory before any request' do
        input, = create_text_document(temp_dir)

        expect do
          client.translate_document(input, File.join(temp_dir, 'missing', 'out.txt'), nil, 'DE')
        end
          .to raise_error(DeepL::Exceptions::DocumentTranslationError, /Cannot write/) { |e|
            expect([e.document_handle, e.cause]).to match([nil, be_a(Errno::ENOENT)])
          }
        expect(a_request(:any, /.*/)).not_to have_been_made
      end

      it 'raises ArgumentError for a missing input file before any request' do
        expect { client.translate_document_upload(File.join(temp_dir, 'missing.txt'), nil, 'DE') }
          .to raise_error(ArgumentError, /Input file does not exist/)
        expect(a_request(:any, /.*/)).not_to have_been_made
      end
    end

    describe '#translate_document_get_status' do
      it 'sends the document key and parses the status' do
        stub_status(status_reply('translating', seconds_remaining: 3, billed_characters: 11))

        status = client.translate_document_get_status(handle)

        expect([status.status, status.seconds_remaining, status.billed_characters, status.ok?])
          .to eq(['translating', 3, 11, true])
      end
    end

    describe '#translate_document_wait_until_done' do
      before { allow(poller).to receive(:sleep) }

      it 'polls every 5 seconds, past unknown statuses, until done and returns the status' do
        stub = stub_status(status_reply('queued'), status_reply('new_status'),
                           status_reply('done', billed_characters: 11))
        expect(poller).to receive(:sleep).with(5).twice

        status = client.translate_document_wait_until_done(handle)

        expect(stub).to have_been_requested.times(3)
        expect([status.status, status.billed_characters]).to eq(['done', 11])
      end

      it 'raises Error with the API message when the translation fails' do
        stub_status(status_reply('error', error_message: 'Unsupported file'))

        expect { client.translate_document_wait_until_done(handle) }
          .to raise_error(DeepL::Exceptions::Error, /Unsupported file/)
      end

      it 'raises Error when timeout_s expires, sleeping no longer than the time left' do
        allow(poller).to receive(:monotonic_now).and_return(0, 3, 8)
        stub = stub_status(status_reply('translating'))
        expect(poller).to receive(:sleep).with(4).once

        expect { client.translate_document_wait_until_done(handle, timeout_s: 7) }
          .to raise_error(DeepL::Exceptions::Error, /within 7 seconds/)
        expect(stub).to have_been_requested.twice
      end
    end

    describe '#translate_document_download' do
      it 'writes the translated document and returns nil' do
        output = File.join(temp_dir, 'result.docx')
        stub_download(Fixtures::BINARY_CONTENT)

        expect(client.translate_document_download(handle, output)).to be_nil
        expect(File.binread(output)).to eq(Fixtures::BINARY_CONTENT)
      end
    end

    describe '#translate_document' do
      before { allow(poller).to receive(:sleep) }

      it 'uploads with the options, waits, downloads and returns the final status' do # rubocop:disable RSpec/ExampleLength
        input, output = create_text_document(temp_dir)
        stub_upload.to_return(upload_reply)
        stub_status(status_reply('translating'), status_reply('done', billed_characters: 11))
        stub_download
        forms = capture_forms

        status = client.translate_document(input, output, 'EN', 'DE', filename: 'name.txt',
                                                                      glossary: 'g-1')

        expect(form_fields(forms.first))
          .to include('filename' => 'name.txt', 'glossary_id' => 'g-1')
        expect([status.status, status.billed_characters]).to eq(['done', 11])
        expect(File.read(output)).to eq('Protonenstrahl')
      end

      it 'raises DocumentTranslationError with the handle when timeout_s expires' do
        allow(poller).to receive(:monotonic_now).and_return(0, 2)
        input, output = create_text_document(temp_dir)
        stub_upload.to_return(upload_reply)
        stub_status(status_reply('queued'))

        expect { client.translate_document(input, output, 'EN', 'DE', timeout_s: 1) }
          .to raise_error(DeepL::Exceptions::DocumentTranslationError, /within 1 seconds/) { |e|
            expect(e.document_handle.document_id).to eq('doc-1')
          }
        expect(File.exist?(output)).to be(false)
      end

      it 'raises DocumentTranslationError without a handle when the upload fails' do
        input, output = create_text_document(temp_dir)
        stub_upload.to_return(reply({ message: 'bad' }, 400))

        expect { client.translate_document(input, output, 'EN', 'DE') }
          .to raise_error(DeepL::Exceptions::DocumentTranslationError, /bad/) { |e|
            expect(e.document_handle).to be_nil
          }
      end

      it 'copies the HTTP status and retryability of the DeepL error it wraps' do
        client = DeepL::Client.new('client-key', server_url: 'https://client.example.test',
                                                 max_retries: 0)
        input, output = create_text_document(temp_dir)
        stub_upload.to_return(reply({ message: 'busy' }, 429))

        expect { client.translate_document(input, output, 'EN', 'DE') }
          .to raise_error(DeepL::Exceptions::DocumentTranslationError) { |e|
            expect([e.http_status_code, e.should_retry?]).to eq([429, true])
          }
      end

      it 'raises DocumentTranslationError and keeps the file when the output file already exists' do
        input, output = create_text_document(temp_dir)
        File.write(output, 'keep me')

        expect { client.translate_document(input, output, 'EN', 'DE') }
          .to raise_error(DeepL::Exceptions::DocumentTranslationError,
                          'File already exists at output path') { |e|
            expect([e.document_handle, e.http_status_code, e.should_retry?])
              .to eq([nil, nil, false])
          }
        expect(File.read(output)).to eq('keep me')
        expect(a_request(:any, /.*/)).not_to have_been_made
      end

      it 'raises ArgumentError for a missing input file before any request' do
        output = File.join(temp_dir, 'out.txt')

        expect { client.translate_document(File.join(temp_dir, 'missing.txt'), output, 'EN', 'DE') }
          .to raise_error(ArgumentError, /Input file does not exist/)
        expect(a_request(:any, /.*/)).not_to have_been_made
      end
    end
  end
end
