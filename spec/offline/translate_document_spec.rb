# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'open3'
require_relative 'offline_helper'

describe DeepL::DocumentApi do
  let(:documents) { DeepL.document }
  let(:handle) { DeepL::Resources::DocumentHandle.new('doc-1', 'key-1', nil, nil) }
  let(:upload_reply) { reply(document_id: 'doc-1', document_key: 'key-1') }
  let(:document_key_body) { { document_key: 'key-1' } }

  include_context 'with a temporary directory'

  def stub_upload
    stub_request(:post, url('/v2/document')).with(
      headers: { 'Authorization' => 'DeepL-Auth-Key k',
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
    documents.upload(input, 'EN', 'DE', filename, **options)
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
    form.reject { |name, _| name == 'file' }.to_h
  end

  def stub_status(*statuses)
    stub_request(:post, url('/v2/document/doc-1')).with(body: document_key_body,
                                                        headers: json_headers)
                                                  .to_return(*statuses)
  end

  def status_reply(status, extra = {})
    reply({ document_id: 'doc-1', status: status }.merge(extra))
  end

  describe '#upload' do
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

      documents.upload(input, nil, 'DE')

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

    it 'treats glossary_id: nil as unset next to glossary or glossary_ids' do
      expect(form_fields(sent_form(glossary: 'g-1', glossary_id: nil)))
        .to include('glossary_id' => 'g-1')
      expect(form_fields(sent_form(glossary_ids: %w[g-1 g-2], glossary_id: nil)))
        .to include('glossary_ids' => 'g-1,g-2').and(satisfy { |f| !f.key?('glossary_id') })
    end

    it 'lets extra_body_parameters add a field and override an existing one' do
      form = sent_form(formality: 'more', extra_body_parameters: { formality: 'less', beta: true })

      expect(form.count { |name, _| name == 'formality' }).to eq(1)
      expect(form_fields(form)).to include('formality' => 'less', 'beta' => 'true')
    end

    it 'raises ArgumentError for invalid glossary_ids without sending a request' do
      input, = create_text_document(temp_dir)

      expect { documents.upload(input, nil, 'DE', nil, glossary_ids: ['g-1']) }
        .to raise_error(ArgumentError, /requires `source_lang`/)
      expect { documents.upload(input, 'EN', 'DE', nil, glossary_ids: ['g-1'], glossary_id: 'g') }
        .to raise_error(ArgumentError, /cannot be used together/)
      expect { documents.upload(input, 'EN', 'DE', nil, glossary_ids: %w[1 2 3 4 5 6]) }
        .to raise_error(ArgumentError, /maximum of 5/)
    end

    it 'retries after a 429 reply' do
      input, = create_text_document(temp_dir)
      stub = stub_upload.to_return(reply({}, 429), upload_reply)

      documents.upload(input, 'EN', 'DE')

      expect(stub).to have_been_requested.twice
    end
  end

  describe '#get_status' do
    it 'sends the document key and derives that a translating document is not finished' do
      stub_status(status_reply('translating', seconds_remaining: 3, billed_characters: 11,
                                              error_message: 'none'))

      status = documents.get_status(handle)

      expect(status.finished?).to be(false)
    end

    it 'parses done as successful and error as failed' do
      stub_status(status_reply('done'), status_reply('error'))

      statuses = Array.new(2) { documents.get_status(handle) }

      expect(statuses.map { |s| [s.successful?, s.error?, s.finished?] })
        .to eq([[true, false, true], [false, true, true]])
    end

    it 'URL-encodes the document ID in the path' do
      stub_request(:post, url('/v2/document/a%20b%2Fc')).to_return(status_reply('done'))

      documents.get_status(DeepL::Resources::DocumentHandle.new('a b/c', 'key-1', nil, nil))
    end
  end

  describe '#download' do
    it 'writes the response body to the output file byte for byte' do
      output = File.join(temp_dir, 'result.docx')
      stub_request(:post, url('/v2/document/doc-1/result'))
        .with(body: document_key_body, headers: json_headers)
        .to_return(status: 200, body: Fixtures::BINARY_CONTENT)

      documents.download(handle, output)

      expect(File.binread(output)).to eq(Fixtures::BINARY_CONTENT)
    end

    it 'writes the bytes unchanged when Encoding.default_internal is set' do
      output = File.join(temp_dir, 'result.docx')
      stub_request(:post, url('/v2/document/doc-1/result'))
        .to_return(status: 200, body: Fixtures::BINARY_CONTENT)
      previous = Encoding.default_internal
      Encoding.default_internal = Encoding::UTF_8

      documents.download(handle, output)

      expect(File.binread(output)).to eq(Fixtures::BINARY_CONTENT)
    ensure
      Encoding.default_internal = previous
    end

    it 'URL-encodes the document ID in the path' do
      stub_request(:post, url('/v2/document/a%20b%2Fc/result')).to_return(status: 200, body: 'x')

      documents.download(DeepL::Resources::DocumentHandle.new('a b/c', 'key-1', nil, nil),
                         File.join(temp_dir, 'result.txt'))
    end

    it 'raises DocumentNotReadyError, a ServerError, for a 503 reply' do
      stub = stub_request(:post, url('/v2/document/doc-1/result'))
             .to_return(reply({ message: 'not ready' }, 503))
      DeepL.configuration.max_network_retries = 0

      expect { documents.download(handle, File.join(temp_dir, 'result.txt')) }
        .to raise_error(DeepL::Exceptions::DocumentNotReadyError, /not ready/) { |e|
          expect([e, e.http_status_code]).to match([be_a(DeepL::Exceptions::ServerError), 503])
        }
      expect(stub).to have_been_requested.once
    end
  end

  describe DeepL::Resources::DocumentHandle, '#wait_until_document_translation_finished' do
    it 'polls the status until the translation is done' do
      stub = stub_status(status_reply('queued'), status_reply('done'))

      status = handle.wait_until_document_translation_finished

      expect(stub).to have_been_requested.twice
      expect(status.successful?).to be(true)
    end

    it 'polls through the connection and configuration the handle was created with' do
      configuration = DeepL::Configuration.new(auth_key: 'other', host: 'https://other.example.test',
                                               max_doc_status_queries: 0)
      other = DeepL::DocumentApi.new(DeepL::API.new(configuration))
      stub_request(:post, 'https://other.example.test/v2/document').to_return(upload_reply)
      stub = stub_request(:post, 'https://other.example.test/v2/document/doc-1')
             .with(headers: { 'Authorization' => 'DeepL-Auth-Key other' })
             .to_return(status_reply('queued'))
      input, = create_text_document(temp_dir)

      other.upload(input, 'EN', 'DE').wait_until_document_translation_finished

      expect(stub).to have_been_requested.once
    end

    it 'does not show the auth key in inspect' do
      configuration = DeepL::Configuration.new(auth_key: 'sdktest-secret-key')
      other = described_class.new('doc-1', 'key-1', nil, nil,
                                  api: DeepL::API.new(configuration))

      expect(other.inspect).not_to include('sdktest-secret-key')
      expect(configuration.inspect).not_to include('sdktest-secret-key')
    end

    it 'stops after max_doc_status_queries polls' do
      DeepL.configuration.max_doc_status_queries = 0
      stub = stub_status(status_reply('queued'))

      status = handle.wait_until_document_translation_finished

      expect(stub).to have_been_requested.once
      expect(status.finished?).to be(false)
    end
  end

  describe '#translate_document' do
    it 'uploads, waits and writes the translated document' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('done'))
      stub_request(:post, url('/v2/document/doc-1/result'))
        .with(body: document_key_body).to_return(status: 200, body: 'Protonenstrahl')

      documents.translate_document(input, output, 'EN', 'DE')

      expect(File.read(output)).to eq('Protonenstrahl')
    end

    it 'passes enable_watermark on to the upload' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('done'))
      stub_request(:post, url('/v2/document/doc-1/result')).to_return(status: 200, body: 'x')
      forms = capture_forms

      documents.translate_document(input, output, 'EN', 'DE', nil, enable_watermark: true)

      expect(form_fields(forms.first)).to include('enable_watermark' => 'true')
    end

    it 'returns the final status' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('done', billed_characters: 11))
      stub_request(:post, url('/v2/document/doc-1/result')).to_return(status: 200, body: 'x')

      status = documents.translate_document(input, output, 'EN', 'DE')

      expect([status.class, status.status, status.billed_characters])
        .to eq([DeepL::Resources::DocumentTranslationStatus, 'done', 11])
    end

    it 'polls until the translation is done, beyond the former limit of 11 status requests' do
      allow(DeepL::Utils::DocumentPoller).to receive(:sleep)
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      replies = Array.new(12) { status_reply('translating') } << status_reply('done')
      stub = stub_status(*replies)
      stub_request(:post, url('/v2/document/doc-1/result')).to_return(status: 200, body: 'x')

      documents.translate_document(input, output, 'EN', 'DE')

      expect(stub).to have_been_requested.times(13)
    end

    it 'raises DocumentTranslationError instead of downloading after max_doc_status_queries' do
      DeepL.configuration.max_doc_status_queries = 0
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('translating'))

      expect { documents.translate_document(input, output, 'EN', 'DE') }
        .to raise_error(DeepL::Exceptions::DocumentTranslationError, /not done/)
    end

    it 'raises IOError and keeps the file when the output file already exists' do
      input, output = create_text_document(temp_dir)
      File.write(output, 'keep me')

      expect { documents.translate_document(input, output, 'EN', 'DE') }
        .to raise_error(IOError, 'File already exists at output path')
      expect(File.read(output)).to eq('keep me')
    end

    it 'raises DocumentTranslationError for an unreadable input without other libraries loaded' do
      script = <<~RUBY
        DeepL.configure { |config| config.auth_key = 'k' }
        begin
          DeepL.document.translate_document('/nonexistent/in.txt', '/nonexistent/out.txt', 'EN', 'DE')
        rescue StandardError => e
          puts e.class
        end
      RUBY
      lib = File.expand_path('../../lib', __dir__)

      # stdout only: stderr carries the deprecation warning of the module API.
      output, = Open3.capture3({ 'PATH' => ENV.fetch('PATH') }, RbConfig.ruby, '-I', lib, '-r',
                               'deepl', '-e', script, unsetenv_others: true)

      expect(output.strip).to eq('DeepL::Exceptions::DocumentTranslationError')
    end

    it 'raises DocumentTranslationError with the API message when the translation fails' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('error', error_message: 'Unsupported file'))

      expect { documents.translate_document(input, output, 'EN', 'DE') }
        .to raise_error(DeepL::Exceptions::DocumentTranslationError, /Unsupported file/)
    end

    it 'raises DocumentTranslationError and leaves no output file when the download fails' do
      input, output = create_text_document(temp_dir)
      stub_upload.to_return(upload_reply)
      stub_status(status_reply('done'))
      stub_request(:post,
                   url('/v2/document/doc-1/result')).to_return(reply({ message: 'gone' }, 404))

      expect { documents.translate_document(input, output, 'EN', 'DE') }
        .to raise_error(DeepL::Exceptions::DocumentTranslationError, /gone/)
      expect(File.exist?(output)).to be(false)
    end
  end
end
