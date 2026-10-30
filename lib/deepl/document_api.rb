# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  class DocumentApi
    def initialize(api, options = {})
      @api = api
      @options = options
    end

    ##
    # Uploads the file at the given +input_file_path+ to be translated from +source_lang+ into
    # +target_lang+. The API interface is async, so you need to poll using the returned
    # `DeepL::Resources::DocumentHandle` until the translation is finished, then you can download it
    #
    # @param [String] input_file_path File path to the file to be translated
    # @param [String, nil] source_lang Source language to use for the translation. `nil` will cause
    #                                  automatic source langauge detection to be used. Must be
    #                                  formatted as ISO 639-1, 2-letter language codes.
    # @param [String] target_lang Target language to use for the translation. Must be formatted as
    #                             ISO 639-1, 2-letter language codes, plus a hyphen "-" with the
    #                             variant identifier for languages with variants/dialects/... .
    # @param [String, nil] filename The filename of the file, including its extension. Used to open
    #                               the different kinds of documents (PDFs, etc). If nil, will use
    #                               the filename of +input_file_path+.
    # @param [Hash] options Additional (body) options for the upload. Notable glossary options:
    #                       +:glossary+ (a glossary ID, `DeepL::Resources::Glossary` or
    #                       `DeepL::Resources::MultilingualGlossary`; replaces the deprecated
    #                       +:glossary_id+) or +:glossary_ids+ (an array of up to 5 glossary IDs
    #                       or objects).
    #                       +:glossary_ids+ requires +source_lang+ to be set, cannot be combined
    #                       with +:glossary+ or +:glossary_id+, and raises `ArgumentError` if
    #                       these rules are violated or more than 5 IDs are provided. Notable
    #                       style/translation memory options (mirroring text translation):
    #                       +:style_rule+ (a style rule ID string or a
    #                       `DeepL::Resources::StyleRule` object),
    #                       +:style_profile+ (a style profile ID string or a
    #                       `DeepL::Resources::StyleProfile` object),
    #                       +:translation_memory+ (a translation memory ID string or a
    #                       `DeepL::Resources::TranslationMemory` object), and
    #                       +:translation_memory_threshold+ (integer 0-100, recommended minimum 75).
    #                       +:enable_watermark+ (boolean) adds a "Translated by DeepL" watermark;
    #                       the API applies it to +docx+ and +pdf+ output only.
    # @param [Hash] additional_headers Additional HTTP headers for the upload.
    # @return [DeepL::Resources::DocumentHandle] Document handle for the uploaded document.

    def upload(input_file_path, source_lang, target_lang, filename = nil, options = {},
               additional_headers = {})
      DeepL::Requests::Document::Upload.new(@api, input_file_path, source_lang, target_lang,
                                            filename, options, additional_headers)
                                       .request
    end

    ##
    # Queries the status of the translation of the document with the given +document_handle+.
    #
    # @param [DeepL::Resources::DocumentHandle] document_handle Handle returned by the `upload`
    # method.
    # @param [Hash] options Additional options for the upload.
    # @param [Hash] additional_headers Additional HTTP headers for the status check.
    # @return [DeepL::Resources::DocumentTranslationStatus] Status of the document translation.

    def get_status(document_handle, options = {}, additional_headers = {})
      DeepL::Requests::Document::GetStatus.new(@api, document_handle.document_id,
                                               document_handle.document_key, options,
                                               additional_headers).request
    end

    ##
    # Downloads the document identified by the +document_handle+ to +output_file+
    #
    # @param [DeepL::Resources::DocumentHandle] document_handle Handle returned by the `upload`
    # method.
    # @param [String] output_file Path to the file to write to. Will be overwritten if the file
    #                             already exists.
    # @return [DeepL::Resources::DocumentTranslationStatus] Status of the document translation.

    def download(document_handle, output_file)
      DeepL::Requests::Document::Download.new(@api, document_handle.document_id,
                                              document_handle.document_key, output_file).request
    end

    ##
    # Translates a document with the DeepL API, `sleep`ing during waiting periods, and returns
    # the final status once the translated document is downloaded. Polls until the translation
    # is done or failed; the deprecated `max_doc_status_queries` limits the number of status
    # requests if it is configured.
    #
    # @raise [DocumentTranslationError] If any error occurs during the process, also when the
    #   translation fails or is not done after `max_doc_status_queries`.
    #
    # @param [String] input_file Path to the file to be translated
    # @param [String] output_file Path to the file to write to. Will be overwritten if the file
    #                             already exists.
    # @param [String, nil] source_lang Source language to use for the translation. `nil` will cause
    #                                  automatic source langauge detection to be used. Must be
    #                                  formatted as ISO 639-1, 2-letter language codes.
    # @param [String] target_lang Target language to use for the translation. Must be formatted as
    #                             ISO 639-1, 2-letter language codes, plus a hyphen "-" with the
    #                             variant identifier for languages with variants/dialects/... .
    # @param [String, nil] filename The filename of the file, including its extension. Used to open
    #                               the different kinds of documents (PDFs, etc). If nil, will use
    #                               the filename of +input_file_path+.
    # @param [Hash] options Additional options for the upload.
    # @param [Hash] additional_headers Additional headers for the upload.
    # @return [DeepL::Resources::DocumentTranslationStatus] Status of the document translation.

    def translate_document(input_file, output_file, source_lang, target_lang, # rubocop:disable Metrics/MethodLength,Metrics/ParameterLists
                           filename = nil, options = {}, additional_headers = {})
      raise IOError, 'File already exists at output path' if File.exist?(output_file)

      begin
        handle = upload(input_file, source_lang, target_lang, filename, options,
                        additional_headers)
        translate_document_wait_and_download(handle, output_file)
      rescue StandardError => e
        FileUtils.rm_f(output_file)
        raise Exceptions::DocumentTranslationError.new(
          "Error occurred during document translation: #{e.message}", handle, e
        )
      end
    end

    private

    def translate_document_wait_and_download(document_handle, output_file)
      doc_status = Utils::DocumentPoller.wait_until_finished(
        @api, document_handle, max_queries: @api.configuration.max_doc_status_queries
      )
      unless doc_status.done?
        raise Exceptions::DocumentTranslationError.new(not_done_message(doc_status),
                                                       document_handle)
      end

      download(document_handle, output_file)
      doc_status
    end

    def not_done_message(doc_status)
      if doc_status.error?
        "Exception when querying document status #{doc_status.error_message}"
      else
        "Document translation not done after max_doc_status_queries (#{doc_status.status})"
      end
    end
  end
end
