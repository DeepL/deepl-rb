# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

# -- Dependencies
require 'fileutils'
require 'json'
require 'net/http'

# -- Deprecation
require_relative 'deepl/deprecation'

# -- Exceptions
require_relative 'deepl/exceptions/error'
require_relative 'deepl/exceptions/validation_error'
require_relative 'deepl/exceptions/request_error'
require_relative 'deepl/exceptions/authorization_failed'
require_relative 'deepl/exceptions/bad_request'
require_relative 'deepl/exceptions/limit_exceeded'
require_relative 'deepl/exceptions/quota_exceeded'
require_relative 'deepl/exceptions/not_found'
require_relative 'deepl/exceptions/not_supported'
require_relative 'deepl/exceptions/request_entity_too_large'
require_relative 'deepl/exceptions/document_translation_error'
require_relative 'deepl/exceptions/server_error'
require_relative 'deepl/exceptions/document_not_ready_error'
require_relative 'deepl/exceptions/connection_error'

# -- Requests
require_relative 'deepl/requests/base'
require_relative 'deepl/requests/document/download'
require_relative 'deepl/requests/document/get_status'
require_relative 'deepl/requests/document/upload'
require_relative 'deepl/requests/glossary/create'
require_relative 'deepl/requests/glossary/destroy'
require_relative 'deepl/requests/glossary/entries'
require_relative 'deepl/requests/glossary/find'
require_relative 'deepl/requests/glossary/language_pairs'
require_relative 'deepl/requests/glossary/list'
require_relative 'deepl/requests/multilingual_glossary/helpers'
require_relative 'deepl/requests/multilingual_glossary/create'
require_relative 'deepl/requests/multilingual_glossary/destroy'
require_relative 'deepl/requests/multilingual_glossary/destroy_dictionary'
require_relative 'deepl/requests/multilingual_glossary/entries'
require_relative 'deepl/requests/multilingual_glossary/find'
require_relative 'deepl/requests/multilingual_glossary/list'
require_relative 'deepl/requests/multilingual_glossary/replace_dictionary'
require_relative 'deepl/requests/multilingual_glossary/update'
require_relative 'deepl/requests/style_rule/helpers'
require_relative 'deepl/requests/style_rule/list'
require_relative 'deepl/requests/style_rule/create'
require_relative 'deepl/requests/style_rule/find'
require_relative 'deepl/requests/style_rule/update'
require_relative 'deepl/requests/style_rule/destroy'
require_relative 'deepl/requests/style_rule/update_configured_rules'
require_relative 'deepl/requests/style_rule/create_custom_instruction'
require_relative 'deepl/requests/style_rule/find_custom_instruction'
require_relative 'deepl/requests/style_rule/update_custom_instruction'
require_relative 'deepl/requests/style_rule/destroy_custom_instruction'
require_relative 'deepl/requests/spoken_terms/helpers'
require_relative 'deepl/requests/spoken_terms/create'
require_relative 'deepl/requests/spoken_terms/list'
require_relative 'deepl/requests/spoken_terms/find'
require_relative 'deepl/requests/spoken_terms/update'
require_relative 'deepl/requests/spoken_terms/entries'
require_relative 'deepl/requests/spoken_terms/replace_term_list'
require_relative 'deepl/requests/spoken_terms/destroy'
require_relative 'deepl/requests/spoken_terms/destroy_term_list'
require_relative 'deepl/requests/style_profile/base'
require_relative 'deepl/requests/style_profile/list'
require_relative 'deepl/requests/style_profile/create'
require_relative 'deepl/requests/style_profile/find'
require_relative 'deepl/requests/style_profile/update'
require_relative 'deepl/requests/style_profile/destroy'
require_relative 'deepl/requests/translation_memory/base'
require_relative 'deepl/requests/translation_memory/storage_base'
require_relative 'deepl/requests/translation_memory/list'
require_relative 'deepl/requests/translation_memory/find'
require_relative 'deepl/requests/translation_memory/segments'
require_relative 'deepl/requests/translation_memory/destroy'
require_relative 'deepl/requests/translation_memory/create_import'
require_relative 'deepl/requests/translation_memory/upload_file'
require_relative 'deepl/requests/translation_memory/create_export'
require_relative 'deepl/requests/translation_memory/find_job'
require_relative 'deepl/requests/translation_memory/download_export'
require_relative 'deepl/requests/languages'
require_relative 'deepl/requests/languages_for_resource'
require_relative 'deepl/requests/language_resources'
require_relative 'deepl/requests/translate'
require_relative 'deepl/requests/usage'
require_relative 'deepl/requests/write_improvements'
require_relative 'deepl/requests/rephrase'
require_relative 'deepl/requests/correct'
require_relative 'deepl/requests/admin/base'
require_relative 'deepl/requests/admin/usage_analytics'
require_relative 'deepl/requests/admin/custom_tag_usage_analytics'
require_relative 'deepl/requests/admin/create_developer_key'
require_relative 'deepl/requests/admin/list_developer_keys'
require_relative 'deepl/requests/admin/update_developer_key'

# -- Responses and resources
require_relative 'deepl/resources/base'
require_relative 'deepl/resources/document_handle'
require_relative 'deepl/resources/document_translation_status'
require_relative 'deepl/resources/glossary'
require_relative 'deepl/resources/multilingual_glossary'
require_relative 'deepl/resources/style_rule'
require_relative 'deepl/resources/spoken_terms'
require_relative 'deepl/resources/style_profile'
require_relative 'deepl/resources/translation_memory'
require_relative 'deepl/resources/translation_memory_segments'
require_relative 'deepl/resources/translation_memory_import'
require_relative 'deepl/resources/translation_memory_export'
require_relative 'deepl/resources/translation_memory_job'
require_relative 'deepl/resources/language'
require_relative 'deepl/resources/language_pair'
require_relative 'deepl/resources/language_resource'
require_relative 'deepl/resources/language_support'
require_relative 'deepl/resources/text'
require_relative 'deepl/resources/usage'
require_relative 'deepl/resources/developer_key'
require_relative 'deepl/resources/admin_usage_report'
require_relative 'deepl/resources/custom_tag_usage_report'

# -- Utils
require_relative 'deepl/utils/exception_builder'
require_relative 'deepl/utils/http_client_builder'
require_relative 'deepl/utils/client_builder'
require_relative 'deepl/utils/backoff_timer'
require_relative 'deepl/utils/time_parser'
require_relative 'deepl/utils/number_parser'
require_relative 'deepl/utils/term_validator'
require_relative 'deepl/utils/document_poller'

# -- Constants
require_relative 'deepl/constants/base_constant'
require_relative 'deepl/constants/document_status_code'
require_relative 'deepl/constants/formality'
require_relative 'deepl/constants/language_include'
require_relative 'deepl/constants/language_resource_name'
require_relative 'deepl/constants/model_type'
require_relative 'deepl/constants/split_sentences'
require_relative 'deepl/constants/tag_handling'
require_relative 'deepl/constants/tag_handling_version'
require_relative 'deepl/constants/tone'
require_relative 'deepl/constants/writing_style'
require_relative 'deepl/constants/admin_usage_group_by'
require_relative 'deepl/constants/custom_tag_usage_aggregate_by'

# -- HTTP Utils
require_relative 'http_client_options'

# -- Version
require_relative 'version'

# -- Other wrappers
require_relative 'deepl/api'
require_relative 'deepl/configuration'
require_relative 'deepl/document_api'
require_relative 'deepl/glossary_api'
require_relative 'deepl/multilingual_glossary_api'
require_relative 'deepl/style_rule_api'
require_relative 'deepl/translation_memory_api'
require_relative 'deepl/app_info'
require_relative 'deepl/client'
require_relative 'deepl/admin_client'

# -- Gem interface
#
# The module-level API (+DeepL.configure+, +DeepL.translate+, +DeepL.glossaries+, ...) keeps its
# configuration in module state. It is deprecated in favour of DeepL::Client and will be removed
# in the next major version.
module DeepL # rubocop:disable Metrics/ModuleLength
  extend self

  ## -- API shortcuts

  # @deprecated Use DeepL::Client instead.
  def api
    deprecated(:api, 'DeepL::Client')
    module_api
  end

  # @deprecated Use DeepL::Client#get_source_languages or DeepL::Client#get_target_languages
  #   instead.
  def languages(options = {})
    deprecated(:languages,
               'DeepL::Client#get_source_languages or DeepL::Client#get_target_languages')
    Requests::Languages.new(module_api, options).request
  end

  ##
  # Retrieves the languages supported by the given resource, each with its per-feature support.
  #
  # @param [String, Symbol] resource Resource to query, for example +'translate_text'+,
  #   +'translate_document'+, +'glossary'+, +'voice'+, +'write'+, +'style_rules'+ or
  #   +'translation_memory'+.
  # @param [Hash] options Additional options:
  #   * +:include+ - A value or an array of values (+'beta'+, +'external'+) to also return beta
  #     languages and features or features relying on third-party providers. By default only
  #     stable languages and features are returned.
  # @return [Array<DeepL::Resources::LanguageSupport>] The supported languages.
  # @raise [ArgumentError] If +resource+ is empty.
  # @deprecated Use DeepL::Client#get_languages_for_resource instead.
  def languages_for_resource(resource, options = {})
    deprecated(:languages_for_resource, 'DeepL::Client#get_languages_for_resource')
    ensure_configured
    Requests::LanguagesForResource.new(module_api, resource, options).request
  end

  ##
  # Retrieves the resources supported by the DeepL API with their features, and whether each
  # feature requires support from the source and/or target language.
  #
  # @return [Array<DeepL::Resources::LanguageResource>] One entry per resource.
  # @deprecated Use DeepL::Client#get_language_resources instead.
  def language_resources(options = {})
    deprecated(:language_resources, 'DeepL::Client#get_language_resources')
    ensure_configured
    Requests::LanguageResources.new(module_api, options).request
  end

  ##
  # Translates +text+ from +source_lang+ into +target_lang+.
  #
  # @param [String, Array<String>] text Text(s) to translate.
  # @param [String, nil] source_lang Source language. `nil` enables automatic detection.
  # @param [String] target_lang Target language.
  # @param [Hash] options Additional (body) options for the translation. Notable options:
  #   * +:glossary+ - A glossary ID, `DeepL::Resources::Glossary` or
  #     `DeepL::Resources::MultilingualGlossary` to use for the translation, sent as
  #     +glossary_id+. Cannot be combined with +:glossary_id+ or +:glossary_ids+.
  #   * +:glossary_id+ - Deprecated, use +:glossary+. A single glossary ID (string).
  #   * +:glossary_ids+ - An array of up to 5 glossary IDs (strings,
  #     `DeepL::Resources::Glossary` or `DeepL::Resources::MultilingualGlossary` objects) to
  #     use for the translation. Glossaries are applied in order (first match wins). Without
  #     +source_lang+, the API detects it. Cannot be combined with +:glossary+ or
  #     +:glossary_id+. Raises `ArgumentError` if these rules are violated or more than 5 IDs
  #     are provided.
  #   * +:style_rule+ - A style rule ID string or a `DeepL::Resources::StyleRule` object.
  #   * +:style_profile+ - A style profile ID string or a `DeepL::Resources::StyleProfile`
  #     object. Applies the profile's glossaries, style rule lists and translation memories.
  # @param [Hash] additional_headers Additional HTTP headers for the translation.
  # @return [DeepL::Resources::Text, Array<DeepL::Resources::Text>] Translated text resource(s).
  # @deprecated Use DeepL::Client#translate_text instead.
  def translate(text, source_lang, target_lang, options = {}, additional_headers = {})
    deprecated(:translate, 'DeepL::Client#translate_text')
    ensure_configured
    Requests::Translate.new(module_api, text, source_lang, target_lang, options,
                            additional_headers).request
  end

  # @deprecated Use DeepL::Client instead.
  def document(options = {})
    deprecated(:document, 'DeepL::Client')
    ensure_configured
    DocumentApi.new(module_api, options)
  end

  # @deprecated Use DeepL::Client instead.
  def glossaries(options = {})
    deprecated(:glossaries, 'DeepL::Client')
    ensure_configured
    GlossaryApi.new(module_api, options)
  end

  # @deprecated Use DeepL::Client instead.
  def multilingual_glossaries(options = {})
    deprecated(:multilingual_glossaries, 'DeepL::Client')
    ensure_configured
    MultilingualGlossaryApi.new(module_api, options)
  end

  # @deprecated Use DeepL::Client instead.
  def style_rules(options = {})
    deprecated(:style_rules, 'DeepL::Client')
    ensure_configured
    StyleRuleApi.new(module_api, options)
  end

  # @deprecated Use DeepL::Client instead.
  def translation_memories(options = {})
    deprecated(:translation_memories, 'DeepL::Client')
    ensure_configured
    TranslationMemoryApi.new(module_api, options)
  end

  # @deprecated Use DeepL::Client#rephrase_text instead.
  def rephrase(text, target_lang = nil, writing_style = nil, tone = nil, options = {}, # rubocop:disable Metrics/ParameterLists
               additional_headers = {})
    deprecated(:rephrase, 'DeepL::Client#rephrase_text')
    ensure_configured
    Requests::Rephrase.new(module_api, text, target_lang, writing_style, tone, options,
                           additional_headers).request
  end

  # @deprecated Use DeepL::Client#correct_text instead.
  def correct(text, target_lang = nil, options = {}, additional_headers = {})
    deprecated(:correct, 'DeepL::Client#correct_text')
    ensure_configured
    Requests::Correct.new(module_api, text, target_lang, options, additional_headers).request
  end

  # @deprecated Use DeepL::Client#get_usage instead.
  def usage(options = {})
    deprecated(:usage, 'DeepL::Client#get_usage')
    ensure_configured
    Requests::Usage.new(module_api, options).request
  end

  # @deprecated Use DeepL::Client with +http_client_options:+ instead.
  def http_client
    deprecated(:http_client, 'DeepL::Client')
    @http_client
  end

  # @deprecated Use DeepL::Client with +http_client_options:+ instead.
  def with_session(client_options = HTTPClientOptions.new) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    raise ArgumentError, 'This method requires a block to be passed in which contains the actual API calls, see README for example usage.' unless block_given? # rubocop:disable Layout/LineLength

    deprecated(:with_session, 'DeepL::Client')
    previous_api_client = module_api.http_client
    previous_api_options = module_api.http_client_options
    previous_http_client = @http_client
    begin
      http = Utils::HTTPClientBuilder.build(module_configuration.host, client_options)
      start_session(http, client_options)
      @http_client = http
      module_api.update_http_client(http, client_options)
      yield
    ensure
      module_api.update_http_client(previous_api_client, previous_api_options)
      @http_client = previous_http_client
      http.finish if http&.started?
    end
  end

  # -- Configuration

  # @deprecated Use DeepL::Client.new instead.
  def configuration
    deprecated(:configuration, 'DeepL::Client.new')
    module_configuration
  end

  # @deprecated Use DeepL::Client.new instead.
  def configure
    deprecated(:configure, 'DeepL::Client.new')
    yield module_configuration if block_given?
    module_configuration.validate!
  end

  private

  def module_configuration
    @configuration ||= Configuration.new # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def module_api
    @api ||= API.new(module_configuration) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  # Opens the session connection within the configured timeout, unless the options set one.
  def start_session(http, client_options)
    timeout = module_configuration.timeout
    http.open_timeout = timeout if client_options.open_timeout.nil? && timeout
    http.start
  end

  def ensure_configured
    module_configuration.validate! if @configuration.nil?
  end

  def deprecated(name, replacement)
    Deprecation.warn_once("DeepL.#{name}",
                          "[DEPRECATION] DeepL.#{name} is deprecated, use #{replacement} instead.",
                          uplevel: 3)
  end
end
