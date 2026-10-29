# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  ##
  # Client for the DeepL API. Every client owns its configuration and HTTP connection: two
  # clients never share options, and nothing is read from environment variables or from the
  # deprecated module-level configuration (+DeepL.configure+).
  #
  #   client = DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), app_info: { app_name: 'my-app',
  #                                                                         app_version: '1.2.3' })
  #
  # All methods may raise a +DeepL::Exceptions::Error+ or a subclass.
  class Client
    DEEPL_SERVER_URL = 'https://api.deepl.com'
    DEEPL_SERVER_URL_FREE = 'https://api-free.deepl.com'
    private_constant :DEEPL_SERVER_URL, :DEEPL_SERVER_URL_FREE

    ##
    # Returns true if +auth_key+ is a DeepL API Free key (it ends with +:fx+).
    #
    # @param [String, nil] auth_key Authentication key.
    # @return [Boolean]
    def self.free_account_auth_key?(auth_key)
      auth_key.to_s.strip.end_with?(':fx')
    end

    ##
    # @param [String] auth_key Authentication key, surrounding whitespace is removed.
    # @param [String, nil] server_url Base URL of the DeepL API, a path prefix is kept. Defaults
    #   to +https://api-free.deepl.com+ for Free keys (ending in +:fx+), else
    #   +https://api.deepl.com+.
    # @param [Hash] headers HTTP headers sent with every DeepL API request (not to pre-signed
    #   storage URLs). A +User-Agent+ replaces the library's; +Authorization+ cannot be replaced.
    # @param [Integer] max_retries Number of retries after the first attempt, for HTTP 429, any
    #   5xx and network failures.
    # @param [Numeric] timeout Timeout of each attempt in seconds, applied to opening the
    #   connection, reading and writing. A longer backoff interval takes precedence.
    # @param [String, nil] proxy Proxy URL, e.g. +http://user:password@proxy.example:8080+.
    # @param [Boolean] send_platform_info Whether to add the OS and Ruby versions to the
    #   +User-Agent+.
    # @param [DeepL::AppInfo, Hash, nil] app_info Your application's +app_name+ and
    #   +app_version+, added to the +User-Agent+.
    # @param [DeepL::HTTPClientOptions, nil] http_client_options Proxy, certificate, SSL
    #   verification and per-phase timeouts. Its timeouts take precedence over +timeout+.
    # @param [Logger, nil] logger Logger for requests and retries.
    # @raise [ArgumentError] If +auth_key+ is empty.
    def initialize(auth_key, server_url: nil, headers: {}, max_retries: 5, timeout: 10, # rubocop:disable Metrics/ParameterLists
                   proxy: nil, send_platform_info: true, app_info: nil, http_client_options: nil,
                   logger: nil)
      free = self.class.free_account_auth_key?(auth_key)
      default_server_url = free ? DEEPL_SERVER_URL_FREE : DEEPL_SERVER_URL
      @api = Utils::ClientBuilder.build_api(
        auth_key, key_name: 'auth_key', server_url: server_url,
                  default_server_url: default_server_url, headers: headers,
                  max_retries: max_retries, timeout: timeout, proxy: proxy,
                  send_platform_info: send_platform_info, app_info: app_info,
                  http_client_options: http_client_options, logger: logger
      )
    end

    ##
    # Translates +text+ from +source_lang+ into +target_lang+. Always requests the billed
    # characters; options set to +nil+ are not sent.
    #
    # @param [String, Array<String>] text Text or texts to translate.
    # @param [String, nil] source_lang Source language, +nil+ to detect it.
    # @param [String] target_lang Target language.
    # @param [Hash] options Translation options, sent as given unless listed here:
    #   * +:glossary+ - A glossary ID, `DeepL::Resources::Glossary` or
    #     `DeepL::Resources::MultilingualGlossary`, sent as +glossary_id+.
    #   * +:glossary_ids+ - Up to 5 glossaries (IDs or objects). Requires +source_lang+ and
    #     cannot be combined with +:glossary+.
    #   * +:style_rule+, +:style_profile+, +:translation_memory+ - An ID or the resource object.
    #   * +:split_sentences+ - +true+/+false+ are sent as +'1'+/+'0'+.
    #   * +:custom_instructions+ - An array of instructions; a string is one instruction.
    #   * +:extra_body_parameters+ - A hash added to the request body last; replaces fields of
    #     the same name.
    #   Other options (+:formality+, +:tag_handling+, +:tag_handling_version+, +:context+,
    #   +:model_type+, ...) are sent unchanged.
    # @return [DeepL::Resources::Text, Array<DeepL::Resources::Text>] One result for a string,
    #   an array for an array (also for a one-element array).
    # @raise [ArgumentError] If the glossary options are combined or more than 5 are given.
    def translate_text(text, source_lang, target_lang, **options)
      result = Requests::Translate.new(api, text, source_lang, target_lang, options).request
      text.is_a?(Array) && !result.is_a?(Array) ? [result] : result
    end

    ##
    # Translates the document at +input_path+ and writes the result to +output_path+: uploads
    # it, waits until the translation is done and downloads it.
    #
    # @param [String] input_path Path of the document to translate.
    # @param [String] output_path Path to write the translated document to. Must not exist.
    # @param [String, nil] source_lang Source language, +nil+ to detect it.
    # @param [String] target_lang Target language.
    # @param [Numeric, nil] timeout_s Maximum time in seconds to wait for the translation after
    #   the upload, +nil+ to wait until it is done.
    # @param [Hash] options The options of #translate_document_upload, including +:filename+.
    # @return [DeepL::Resources::DocumentTranslationStatus] The final status, +done+.
    # @raise [IOError] If +output_path+ already exists; nothing is uploaded.
    # @raise [DeepL::Exceptions::DocumentTranslationError] For any other failure, also a failed
    #   translation or an expired +timeout_s+. Its +document_handle+ is set once the upload
    #   succeeded, so the document can still be queried and downloaded.
    def translate_document(input_path, output_path, source_lang, target_lang, timeout_s: nil, # rubocop:disable Metrics/MethodLength
                           **options)
      raise IOError, 'File already exists at output path' if File.exist?(output_path)

      handle = nil
      begin
        handle = translate_document_upload(input_path, source_lang, target_lang, **options)
        status = translate_document_wait_until_done(handle, timeout_s: timeout_s)
        translate_document_download(handle, output_path)
        status
      rescue StandardError => e
        FileUtils.rm_f(output_path)
        raise Exceptions::DocumentTranslationError.new(
          "Error occurred during document translation: #{e.message}", handle
        )
      end
    end

    ##
    # Uploads the document at +input_path+ for translation. Options set to +nil+ are not sent.
    #
    # @param [String] input_path Path of the document to translate.
    # @param [String, nil] source_lang Source language, +nil+ to detect it.
    # @param [String] target_lang Target language.
    # @param [Hash] options Document translation options:
    #   * +:filename+ - File name sent with the upload, including its extension. Defaults to the
    #     base name of +input_path+.
    #   * +:formality+, +:output_format+ - Sent unchanged.
    #   * +:enable_watermark+ - +true+ or +false+.
    #   * +:glossary+ - A glossary ID, `DeepL::Resources::Glossary` or
    #     `DeepL::Resources::MultilingualGlossary`, sent as +glossary_id+.
    #   * +:glossary_ids+ - Up to 5 glossaries (IDs or objects). Requires +source_lang+ and
    #     cannot be combined with +:glossary+.
    #   * +:style_rule+, +:style_profile+, +:translation_memory+ - An ID or the resource object.
    #   * +:translation_memory_threshold+ - Integer 0-100.
    #   * +:extra_body_parameters+ - A hash added to the form last; replaces fields of the same
    #     name.
    # @return [DeepL::Resources::DocumentHandle] Handle of the uploaded document.
    # @raise [ArgumentError] If the glossary options are combined or more than 5 are given.
    def translate_document_upload(input_path, source_lang, target_lang, **options)
      filename = options.delete(:filename)
      Requests::Document::Upload.new(api, input_path, source_lang, target_lang, filename,
                                     options).request
    end

    ##
    # Queries the status of a document translation once.
    #
    # @param [DeepL::Resources::DocumentHandle] handle Handle returned by the upload.
    # @return [DeepL::Resources::DocumentTranslationStatus]
    def translate_document_get_status(handle)
      Requests::Document::GetStatus.new(api, handle.document_id, handle.document_key).request
    end

    ##
    # Polls the status of a document translation every 5 seconds until it is done.
    #
    # @param [DeepL::Resources::DocumentHandle] handle Handle returned by the upload.
    # @param [Numeric, nil] timeout_s Maximum time to wait in seconds, +nil+ to wait until the
    #   translation is done or failed.
    # @return [DeepL::Resources::DocumentTranslationStatus] The final status, +done+.
    # @raise [DeepL::Exceptions::Error] If the translation fails (with the API's error message)
    #   or +timeout_s+ expires.
    def translate_document_wait_until_done(handle, timeout_s: nil)
      Utils::DocumentPoller.wait_until_done(api, handle, timeout_s: timeout_s)
    end

    ##
    # Downloads the translated document to +output_path+, overwriting an existing file.
    #
    # @param [DeepL::Resources::DocumentHandle] handle Handle returned by the upload.
    # @param [String] output_path Path to write the translated document to.
    # @return [nil]
    # @raise [DeepL::Exceptions::DocumentNotReadyError] If the translation is not done yet.
    def translate_document_download(handle, output_path)
      Requests::Document::Download.new(api, handle.document_id, handle.document_key,
                                       output_path).request
      nil
    end

    def inspect
      "#<#{self.class.name} server_url=#{configuration.host}>"
    end

    private

    attr_reader :api

    def configuration
      api.configuration
    end
  end
end
