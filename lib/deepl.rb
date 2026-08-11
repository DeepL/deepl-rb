# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

# -- Dependencies
require 'json'
require 'net/http'

# -- Exceptions
require_relative 'deepl/exceptions/error'
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
require_relative 'deepl/requests/translate'
require_relative 'deepl/requests/usage'
require_relative 'deepl/requests/rephrase'

# -- Responses and resources
require_relative 'deepl/resources/base'
require_relative 'deepl/resources/document_handle'
require_relative 'deepl/resources/document_translation_status'
require_relative 'deepl/resources/glossary'
require_relative 'deepl/resources/style_rule'
require_relative 'deepl/resources/translation_memory'
require_relative 'deepl/resources/translation_memory_segments'
require_relative 'deepl/resources/translation_memory_import'
require_relative 'deepl/resources/translation_memory_export'
require_relative 'deepl/resources/translation_memory_job'
require_relative 'deepl/resources/language'
require_relative 'deepl/resources/language_pair'
require_relative 'deepl/resources/text'
require_relative 'deepl/resources/usage'

# -- Utils
require_relative 'deepl/utils/exception_builder'
require_relative 'deepl/utils/backoff_timer'
require_relative 'deepl/utils/time_parser'

# -- Constants
require_relative 'deepl/constants/base_constant'
require_relative 'deepl/constants/formality'
require_relative 'deepl/constants/model_type'
require_relative 'deepl/constants/split_sentences'
require_relative 'deepl/constants/tag_handling'
require_relative 'deepl/constants/tone'
require_relative 'deepl/constants/writing_style'

# -- HTTP Utils
require_relative 'http_client_options'

# -- Version
require_relative 'version'

# -- Other wrappers
require_relative 'deepl/api'
require_relative 'deepl/configuration'
require_relative 'deepl/document_api'
require_relative 'deepl/glossary_api'
require_relative 'deepl/style_rule_api'
require_relative 'deepl/translation_memory_api'

# -- Gem interface
module DeepL
  extend self

  ## -- API shortcuts

  def api
    @api ||= API.new(configuration)
  end

  def languages(options = {})
    Requests::Languages.new(api, options).request
  end

  ##
  # Translates +text+ from +source_lang+ into +target_lang+.
  #
  # @param [String, Array<String>] text Text(s) to translate.
  # @param [String, nil] source_lang Source language. `nil` enables automatic detection.
  # @param [String] target_lang Target language.
  # @param [Hash] options Additional (body) options for the translation. Notable options:
  #   * +:glossary_id+ - A single glossary ID (string) to use for the translation. Requires
  #     +source_lang+ to be set. Cannot be combined with +:glossary_ids+.
  #   * +:glossary_ids+ - An array of up to 5 glossary IDs (strings or
  #     `DeepL::Resources::Glossary` objects) to use for the translation. Glossaries are applied
  #     in order (first match wins). Requires +source_lang+ to be set. Cannot be combined with
  #     +:glossary_id+. Raises `ArgumentError` if these rules are violated or more than 5 IDs are
  #     provided.
  # @param [Hash] additional_headers Additional HTTP headers for the translation.
  # @return [DeepL::Resources::Text, Array<DeepL::Resources::Text>] Translated text resource(s).
  def translate(text, source_lang, target_lang, options = {}, additional_headers = {})
    configure if @configuration.nil?
    Requests::Translate.new(api, text, source_lang, target_lang, options,
                            additional_headers).request
  end

  def document(options = {})
    configure if @configuration.nil?
    DocumentApi.new(api, options)
  end

  def glossaries(options = {})
    configure if @configuration.nil?
    GlossaryApi.new(api, options)
  end

  def style_rules(options = {})
    configure if @configuration.nil?
    StyleRuleApi.new(api, options)
  end

  def translation_memories(options = {})
    configure if @configuration.nil?
    TranslationMemoryApi.new(api, options)
  end

  def rephrase(text, target_lang = nil, writing_style = nil, tone = nil, options = {}, # rubocop:disable Metrics/ParameterLists
               additional_headers = {})
    configure if @configuration.nil?
    Requests::Rephrase.new(api, text, target_lang, writing_style, tone, options,
                           additional_headers).request
  end

  def usage(options = {})
    configure if @configuration.nil?
    Requests::Usage.new(api, options).request
  end

  def http_client
    @http_client
  end

  def with_session(client_options = HTTPClientOptions.new()) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    raise ArgumentError 'This method requires a block to be passed in which contains the actual API calls, see README for example usage.' unless block_given? # rubocop:disable Layout/LineLength

    has_proxy = client_options.proxy.key?('proxy_addr') and client_options.proxy.key?('proxy_port')
    begin
      uri = URI(configuration.host)
      http = Net::HTTP.new(uri.host, uri.port, has_proxy ? client_options.proxy['proxy_addr'] : nil,
                           has_proxy ? client_options.proxy['proxy_port'] : nil)
      http.use_ssl = client_options.enable_ssl_verification
      http.ca_file = client_options.cert_path if client_options.cert_path
      http.open_timeout = client_options.open_timeout unless client_options.open_timeout.nil?
      http.read_timeout = client_options.read_timeout unless client_options.read_timeout.nil?
      http.write_timeout = client_options.write_timeout unless client_options.write_timeout.nil?
      http.ssl_timeout = client_options.ssl_timeout unless client_options.ssl_timeout.nil?
      http.start
      @http_client = http
      api.update_http_client(http)
      yield
    ensure
      http.finish
    end
  end

  # -- Configuration

  def configuration
    @configuration ||= Configuration.new
  end

  def configure
    yield configuration if block_given?
    configuration.validate!
  end
end
