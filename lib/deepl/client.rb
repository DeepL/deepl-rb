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
  class Client # rubocop:disable Metrics/ClassLength
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

    ##
    # Rephrases +text+, optionally into another variant or language and with a writing style
    # or tone. Options set to +nil+ are not sent.
    #
    # @param [String, Array<String>] text Text or texts to rephrase.
    # @param [String, nil] target_lang Target language, +nil+ to keep the language of the text.
    # @param [String, nil] writing_style Writing style, see +DeepL::Constants::WritingStyle+.
    #   Cannot be combined with +tone+.
    # @param [String, nil] tone Tone, see +DeepL::Constants::Tone+.
    # @param [Hash] options +:extra_body_parameters+, a hash added to the request body last;
    #   replaces fields of the same name. Other options are sent unchanged.
    # @return [DeepL::Resources::Text, Array<DeepL::Resources::Text>] One result for a string,
    #   an array for an array (also for a one-element array).
    # @raise [DeepL::Exceptions::Error] If the response has fewer improvements than texts.
    def rephrase_text(text, target_lang = nil, writing_style: nil, tone: nil, **options)
      result = Requests::Rephrase.new(api, text, target_lang, writing_style, tone,
                                      options.compact).request
      text.is_a?(Array) && !result.is_a?(Array) ? [result] : result
    end

    ##
    # Corrects the grammar, spelling and punctuation of +text+. Options set to +nil+ are not
    # sent.
    #
    # @param [String, Array<String>] text Text or texts to correct.
    # @param [String, nil] target_lang Target language, +nil+ to keep the language of the text.
    # @param [Hash] options +:extra_body_parameters+, a hash added to the request body last;
    #   replaces fields of the same name. Other options are sent unchanged.
    # @return [DeepL::Resources::Text, Array<DeepL::Resources::Text>] One result for a string,
    #   an array for an array (also for a one-element array).
    # @raise [ArgumentError] If +text+ is empty or contains an empty string.
    # @raise [DeepL::Exceptions::Error] If the response has fewer improvements than texts.
    def correct_text(text, target_lang = nil, **options)
      Requests::Correct.new(api, text, target_lang, options.compact).request
    end

    ##
    # Retrieves the languages that can be translated from, with upper-case codes (+EN+, +DE+).
    #
    # @return [Array<DeepL::Resources::Language>] The source languages;
    #   +supports_formality?+ is +nil+ for each.
    def get_source_languages # rubocop:disable Naming/AccessorMethodName
      Requests::Languages.new(api, type: :source).request
    end

    ##
    # Retrieves the languages that can be translated into, with upper-case codes (+EN-GB+, +DE+).
    #
    # @return [Array<DeepL::Resources::Language>] The target languages, each with
    #   +supports_formality?+ set to +true+ or +false+.
    def get_target_languages # rubocop:disable Naming/AccessorMethodName
      Requests::Languages.new(api, type: :target).request
    end

    ##
    # Retrieves the resources supported by the DeepL API with their features, and whether each
    # feature requires support from the source and/or target language.
    #
    # @return [Array<DeepL::Resources::LanguageResource>] One entry per resource.
    def get_language_resources # rubocop:disable Naming/AccessorMethodName
      Requests::LanguageResources.new(api).request
    end

    ##
    # Retrieves the languages supported by +resource+, each with its per-feature support. The
    # language codes are returned as the API sends them.
    #
    # @param [String, Symbol] resource Resource to query, see
    #   +DeepL::Constants::LanguageResourceName+. Other values are sent unchanged.
    # @param [String, Array<String>, nil] include Also return beta languages and features or
    #   features relying on third-party providers, see +DeepL::Constants::LanguageInclude+. Sent
    #   as one +include+ query parameter per value; +nil+ sends none, which returns stable
    #   languages and features only.
    # @return [Array<DeepL::Resources::LanguageSupport>] The supported languages.
    # @raise [ArgumentError] If +resource+ is empty.
    def get_languages_for_resource(resource, include: nil)
      Requests::LanguagesForResource.new(api, resource, { include: include }.compact).request
    end

    ##
    # Creates a spoken terms collection, which improves the transcription of the given terms.
    #
    # @param [String] name Name of the collection.
    # @param [Array<DeepL::Resources::SpokenTermsEntries, Hash>] term_lists One entry per
    #   language. A hash needs the keys +:lang+ and +:entries+ (an array of terms).
    # @param [Hash] options +:extra_body_parameters+, a hash added to the request body last.
    # @return [DeepL::Resources::SpokenTerms] The created collection.
    # @raise [ArgumentError] If a term is empty after stripping surrounding whitespace or
    #   contains a control character.
    def create_spoken_terms(name, term_lists, **options)
      Requests::SpokenTerms::Create.new(api, name, term_lists, options).request
    end

    ##
    # Lists all spoken terms collections.
    #
    # @return [Array<DeepL::Resources::SpokenTerms>]
    def list_spoken_terms
      Requests::SpokenTerms::List.new(api).request
    end

    ##
    # Retrieves a spoken terms collection.
    #
    # @param [String, DeepL::Resources::SpokenTerms] spoken_terms ID or collection.
    # @return [DeepL::Resources::SpokenTerms]
    # @raise [DeepL::Exceptions::NotFound] If the collection does not exist.
    def get_spoken_terms(spoken_terms)
      Requests::SpokenTerms::Find.new(api, spoken_terms).request
    end

    ##
    # Renames a collection and/or merges terms into its lists. Arguments left +nil+ are not
    # sent; without any, an empty object is sent.
    #
    # @param [String, DeepL::Resources::SpokenTerms] spoken_terms ID or collection.
    # @param [String, nil] name New name.
    # @param [Array<DeepL::Resources::SpokenTermsEntries, Hash>, nil] term_lists Terms to merge
    #   into the list of each language; a new language adds a list.
    # @param [Hash] options +:extra_body_parameters+, a hash added to the request body last.
    # @return [DeepL::Resources::SpokenTerms] The updated collection.
    # @raise [ArgumentError] If a term is empty after stripping or contains a control character.
    def update_spoken_terms(spoken_terms, name: nil, term_lists: nil, **options)
      Requests::SpokenTerms::Update.new(api, spoken_terms, name, term_lists, options).request
    end

    ##
    # Deletes a spoken terms collection.
    #
    # @param [String, DeepL::Resources::SpokenTerms] spoken_terms ID or collection.
    # @return [nil]
    def delete_spoken_terms(spoken_terms)
      Requests::SpokenTerms::Destroy.new(api, spoken_terms).request
    end

    ##
    # Retrieves the terms of one language of a collection.
    #
    # @param [String, DeepL::Resources::SpokenTerms] spoken_terms ID or collection.
    # @param [String] lang Language code, for example +'en'+.
    # @return [DeepL::Resources::SpokenTermsEntries]
    def get_spoken_terms_entries(spoken_terms, lang)
      Requests::SpokenTerms::Entries.new(api, spoken_terms, lang).request
    end

    ##
    # Replaces the terms of one language, or adds the list if the language is new.
    #
    # @param [String, DeepL::Resources::SpokenTerms] spoken_terms ID or collection.
    # @param [DeepL::Resources::SpokenTermsEntries, Hash] entries The language and its terms; a
    #   hash needs the keys +:lang+ and +:entries+.
    # @param [Hash] options +:extra_body_parameters+, a hash added to the request body last.
    # @return [DeepL::Resources::SpokenTermsList]
    # @raise [ArgumentError] If a term is empty after stripping or contains a control character.
    def replace_spoken_terms_list(spoken_terms, entries, **options)
      Requests::SpokenTerms::ReplaceTermList.new(api, spoken_terms, entries, options).request
    end

    ##
    # Deletes the term list of one language of a collection.
    #
    # @param [String, DeepL::Resources::SpokenTerms] spoken_terms ID or collection.
    # @param [String] lang Language code, for example +'en'+.
    # @return [nil]
    def delete_spoken_terms_list(spoken_terms, lang)
      Requests::SpokenTerms::DestroyTermList.new(api, spoken_terms, lang).request
    end

    ##
    # Lists style profiles, one page at a time. Arguments left +nil+ are not sent.
    #
    # @param [Integer, nil] page Index of the page, starting at 0 (API default: 0).
    # @param [Integer, nil] page_size Style profiles per page (API default: 10, at most 100).
    # @return [Array<DeepL::Resources::StyleProfile>]
    def list_style_profiles(page: nil, page_size: nil)
      Requests::StyleProfile::List.new(api, { page: page, page_size: page_size }.compact).request
    end

    ##
    # Creates a style profile, which links glossaries, style rule lists and translation
    # memories. Keywords left +nil+ are not sent. If a component cannot be used, the request
    # fails and no style profile is created.
    #
    # @param [String] name Name of the style profile.
    # @param [String, nil] description Free-text description.
    # @param [String, nil] industry The industry the style profile is written for.
    # @param [Array<String, DeepL::Resources::Glossary, DeepL::Resources::MultilingualGlossary>,
    #   nil] glossary_ids Glossaries to link (IDs or objects), highest priority first.
    # @param [Array<String, DeepL::Resources::StyleRule>, nil] style_rule_ids Style rule lists.
    # @param [Array<String, DeepL::Resources::TranslationMemory>, nil] translation_memory_ids
    #   Translation memories.
    # @param [Boolean, nil] glossary_priority_order_enabled Whether the order of +glossary_ids+
    #   sets priority.
    # @param [Hash] options +:extra_body_parameters+, a hash added to the request body last.
    # @return [DeepL::Resources::StyleProfile] The created style profile.
    def create_style_profile(name, description: nil, industry: nil, glossary_ids: nil, # rubocop:disable Metrics/ParameterLists
                             style_rule_ids: nil, translation_memory_ids: nil,
                             glossary_priority_order_enabled: nil, **options)
      fields = { description: description, industry: industry, glossary_ids: glossary_ids,
                 style_rule_ids: style_rule_ids, translation_memory_ids: translation_memory_ids,
                 glossary_priority_order_enabled: glossary_priority_order_enabled }
      Requests::StyleProfile::Create.new(api, name, fields, options).request
    end

    ##
    # Retrieves a style profile.
    #
    # @param [String, DeepL::Resources::StyleProfile] style_profile ID or style profile.
    # @return [DeepL::Resources::StyleProfile]
    # @raise [ArgumentError] If the ID is empty.
    # @raise [DeepL::Exceptions::NotFound] If the style profile does not exist.
    def get_style_profile(style_profile)
      Requests::StyleProfile::Find.new(api, style_profile).request
    end

    ##
    # Updates a style profile. Keywords left +nil+ are not sent and leave the field unchanged;
    # without any, an empty object is sent. An empty string clears +description+ or +industry+.
    # A component list replaces the linked list in full; an empty array unlinks all components
    # of that kind.
    #
    # @param [String, DeepL::Resources::StyleProfile] style_profile ID or style profile.
    # @param [String, nil] name New name.
    # @param [Hash] options The keywords of #create_style_profile, including
    #   +:extra_body_parameters+.
    # @return [DeepL::Resources::StyleProfile] The updated style profile.
    # @raise [ArgumentError] If the ID is empty.
    def update_style_profile(style_profile, name: nil, description: nil, industry: nil, # rubocop:disable Metrics/ParameterLists
                             glossary_ids: nil, style_rule_ids: nil, translation_memory_ids: nil,
                             glossary_priority_order_enabled: nil, **options)
      fields = { name: name, description: description, industry: industry,
                 glossary_ids: glossary_ids, style_rule_ids: style_rule_ids,
                 translation_memory_ids: translation_memory_ids,
                 glossary_priority_order_enabled: glossary_priority_order_enabled }
      Requests::StyleProfile::Update.new(api, style_profile, fields, options).request
    end

    ##
    # Deletes a style profile.
    #
    # @param [String, DeepL::Resources::StyleProfile] style_profile ID or style profile.
    # @return [nil]
    # @raise [ArgumentError] If the ID is empty.
    def delete_style_profile(style_profile)
      Requests::StyleProfile::Destroy.new(api, style_profile).request
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
