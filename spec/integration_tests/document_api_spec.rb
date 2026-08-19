# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::DocumentApi do
  include_context 'with temp dir'

  let(:default_lang_args) { { source_lang: 'EN', target_lang: 'DE' } }

  describe '#translate_document' do
    it 'Translates a document from a filepath' do
      File.unlink(output_document_path)
      source_lang = default_lang_args[:source_lang]
      target_lang = default_lang_args[:target_lang]
      example_doc_path = example_document_path(source_lang)
      DeepL.document.translate_document(example_doc_path, output_document_path,
                                        source_lang, target_lang, File.basename(example_doc_path),
                                        {})
      output_file_contents = File.read(output_document_path)

      expect(example_document_translation(target_lang)).to eq(output_file_contents)
    end
    it 'raises an IOError when the output file already exists' do
      source_lang = default_lang_args[:source_lang]
      target_lang = default_lang_args[:target_lang]
      example_doc_path = example_document_path(source_lang)

      FileUtils.touch(output_document_path)

      expect do
        DeepL.document.translate_document(example_doc_path, output_document_path,
          source_lang, target_lang, File.basename(example_doc_path),
          {})
      end.to raise_error(IOError)
    end

    it 'Translates a document from a filepath without a filename' do
      File.unlink(output_document_path)
      source_lang = default_lang_args[:source_lang]
      target_lang = default_lang_args[:target_lang]
      example_doc_path = example_document_path(source_lang)
      DeepL.document.translate_document(example_doc_path, output_document_path,
                                        source_lang, target_lang)
      output_file_contents = File.read(output_document_path)

      expect(example_document_translation(target_lang)).to eq(output_file_contents)
    end

    it 'Translates a document using the lower-level methods and returns the correct status' do # rubocop:disable RSpec/ExampleLength
      File.unlink(output_document_path)
      source_lang = default_lang_args[:source_lang]
      target_lang = default_lang_args[:target_lang]
      example_doc_path = example_document_path(source_lang)

      handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                     File.basename(example_doc_path), {})
      doc_status = handle.wait_until_document_translation_finished
      DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
      output_file_contents = File.read(output_document_path)

      expect(example_document_translation(target_lang)).to eq(output_file_contents)
      expect(doc_status.billed_characters).to eq(example_document_translation(source_lang).length)
      expect(doc_status.status).to eq('done')
    end

    it 'Translates a document after retrying the upload once', :mock_server_only do # rubocop:disable RSpec/ExampleLength
      File.unlink(output_document_path)
      source_lang = default_lang_args[:source_lang]
      target_lang = default_lang_args[:target_lang]
      example_doc_path = example_document_path(source_lang)
      doc_status = nil
      DeepL.with_session(DeepL::HTTPClientOptions.new({}, nil, enable_ssl_verification: false,
                                                               read_timeout: 1.0)) do |_session|
        handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                       File.basename(example_doc_path), {}, no_response_header(1))
        doc_status = handle.wait_until_document_translation_finished
        DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
      end
      output_file_contents = File.read(output_document_path)

      expect(output_file_contents).to eq(example_document_translation(target_lang))
      expect(doc_status.billed_characters).to eq(example_document_translation(source_lang).length)
      expect(doc_status.status).to eq('done')
    end
  end

  it 'Translates a document after waiting', :mock_server_only do # rubocop:disable RSpec/ExampleLength
    File.unlink(output_document_path)
    source_lang = default_lang_args[:source_lang]
    target_lang = default_lang_args[:target_lang]
    example_doc_path = example_document_path(source_lang)
    doc_status = nil
    DeepL.with_session(DeepL::HTTPClientOptions.new({}, nil,
                                                    enable_ssl_verification: false)) do |_session|
      handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                     File.basename(example_doc_path), {},
                                     doc_translation_queue_time_header(2000).merge(doc_translation_translation_time_header(2000))) # rubocop:disable Layout/LineLength
      doc_status = handle.wait_until_document_translation_finished
      DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
    end
    output_file_contents = File.read(output_document_path)

    expect(output_file_contents).to eq(example_document_translation(target_lang))
    expect(doc_status.billed_characters).to eq(example_document_translation(source_lang).length)
    expect(doc_status.status).to eq('done')
  end

  it 'Translates a large document', :mock_server_only do # rubocop:disable RSpec/ExampleLength
    File.unlink(output_document_path)
    source_lang = default_lang_args[:source_lang]
    target_lang = default_lang_args[:target_lang]
    example_doc_path = example_large_document_path(source_lang)
    doc_status = nil
    DeepL.with_session(DeepL::HTTPClientOptions.new({}, nil,
                                                    enable_ssl_verification: false)) do |_session|
      handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                     File.basename(example_doc_path), {})
      doc_status = handle.wait_until_document_translation_finished
      DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
    end
    output_file_contents = File.read(output_document_path)

    expect(output_file_contents).to eq(example_large_document_translation(target_lang))
    expect(doc_status.billed_characters).to eq(
      example_large_document_translation(source_lang).length
    )
    expect(doc_status.status).to eq('done')
  end

  it 'Translates a document with formality set', :mock_server_only do # rubocop:disable RSpec/ExampleLength
    File.unlink(output_document_path)
    source_lang = default_lang_args[:source_lang]
    target_lang = default_lang_args[:target_lang]
    example_doc_path = example_large_document_path(source_lang)
    doc_status = nil
    DeepL.with_session(DeepL::HTTPClientOptions.new({}, nil,
                                                    enable_ssl_verification: false)) do |_session|
      handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                     File.basename(example_doc_path),
                                     { 'formality' => 'prefer_more' })
      doc_status = handle.wait_until_document_translation_finished
      DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
    end
    output_file_contents = File.read(output_document_path)

    expect(output_file_contents).to eq(example_large_document_translation(target_lang))
    expect(doc_status.billed_characters).to eq(
      example_large_document_translation(source_lang).length
    )
    expect(doc_status.status).to eq('done')
  end

  it 'Translates a document with a style_id set', :mock_server_only do # rubocop:disable RSpec/ExampleLength
    File.unlink(output_document_path)
    # Mock's default style rule (dca2e053...) has language `en`, so the target
    # language must be English.
    source_lang = 'DE'
    target_lang = 'EN-US'
    example_doc_path = example_document_path(source_lang)
    style_id = 'dca2e053-8ae5-45e6-a0d2-881156e7f4e4'
    doc_status = nil
    DeepL.with_session(DeepL::HTTPClientOptions.new({}, nil,
                                                    enable_ssl_verification: false)) do |_session|
      handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                     File.basename(example_doc_path),
                                     { style_rule: style_id })
      doc_status = handle.wait_until_document_translation_finished
      DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
    end
    output_file_contents = File.read(output_document_path)

    expect(example_document_translation(target_lang)).to eq(output_file_contents)
    expect(doc_status.status).to eq('done')
  end

  it 'Translates a document with a translation_memory_id set', :mock_server_only do # rubocop:disable RSpec/ExampleLength
    File.unlink(output_document_path)
    # Mock's default translation memory (a74d88fb...) has source `de` and
    # targets `en`/`es`/`fr`, so translate DE -> EN-US.
    source_lang = 'DE'
    target_lang = 'EN-US'
    example_doc_path = example_document_path(source_lang)
    translation_memory_id = 'a74d88fb-ed2a-4943-a664-a4512398b994'
    doc_status = nil
    DeepL.with_session(DeepL::HTTPClientOptions.new({}, nil,
                                                    enable_ssl_verification: false)) do |_session|
      handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                     File.basename(example_doc_path),
                                     { translation_memory: translation_memory_id,
                                       translation_memory_threshold: 80 })
      doc_status = handle.wait_until_document_translation_finished
      DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
    end
    output_file_contents = File.read(output_document_path)

    expect(example_document_translation(target_lang)).to eq(output_file_contents)
    expect(doc_status.status).to eq('done')
  end

  it 'Translates a document with extra_body_parameters' do # rubocop:disable RSpec/ExampleLength
    File.unlink(output_document_path)
    source_lang = default_lang_args[:source_lang]
    target_lang = default_lang_args[:target_lang]
    example_doc_path = example_document_path(source_lang)

    handle = DeepL.document.upload(example_doc_path, source_lang, target_lang,
                                   File.basename(example_doc_path),
                                   {
                                     extra_body_parameters: {
                                       target_lang: 'FR',
                                       debug: '1'
                                     }
                                   })
    doc_status = handle.wait_until_document_translation_finished
    DeepL.document.download(handle, output_document_path) if doc_status.status != 'error'
    output_file_contents = File.read(output_document_path)

    expect(example_document_translation('FR')).to eq(output_file_contents)
    expect(doc_status.status).to eq('done')
  end
end
