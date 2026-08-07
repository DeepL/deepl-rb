# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Document
      class Upload < Base
        attr_reader :input_file_path, :source_lang, :target_lang, :filename

        SUPPORTED_OPTIONS = %w[formality glossary_id output_format].freeze

        def initialize(api, input_file_path, source_lang, target_lang, filename = nil, # rubocop:disable Metrics/ParameterLists
                       options = {}, additional_headers = {})
          super(api, options, additional_headers)
          @input_file_path = input_file_path
          @source_lang = source_lang
          @target_lang = target_lang
          @filename = filename
        end

        def request
          File.open(input_file_path, 'rb') do |input_file|
            form_data = build_base_form_data(input_file)
            apply_extra_body_parameters_to_form(form_data)
            build_doc_handle(*execute_request_with_retries(post_request_with_file(form_data),
                                                           [input_file]))
          end
        end

        def details
          "HTTP Headers: #{headers}\nPayload #{[
            ['file', "File at #{input_file_path} opened in binary mode"],
            ['source_lang', source_lang], ['target_lang', target_lang], ['filename', filename]
          ]}"
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        def build_base_form_data(input_file)
          form_data = [
            ['file', input_file], ['source_lang', source_lang],
            ['target_lang', target_lang]
          ]
          filename_param = filename || File.basename(input_file_path)
          form_data.push(['filename', filename_param]) unless filename_param.nil?
          add_extra_options_to_form(form_data)
          form_data
        end

        def add_extra_options_to_form(form_data)
          add_supported_options_to_form(form_data)
          add_glossary_ids_to_form(form_data)
          add_style_rule_to_form(form_data)
          add_translation_memory_to_form(form_data)
          add_translation_memory_threshold_to_form(form_data)
        end

        # Validates and serializes the `glossary_ids` option (see
        # `DeepL::Requests::Base#build_glossary_ids_param`) and appends it to the form data as a
        # comma-separated `glossary_ids` field. Requires `source_lang`, cannot be combined with
        # the singular `glossary_id` option, and allows at most 5 IDs.
        def add_glossary_ids_to_form(form_data)
          glossary_ids = build_glossary_ids_param(source_lang)
          form_data.push(['glossary_ids', glossary_ids.join(',')]) unless glossary_ids.nil?
        end

        # Serializes the `style_rule` option and appends it to the form data as a `style_id`
        # field. Mirrors text translation: accepts either a style rule ID string or a
        # `DeepL::Resources::StyleRule` object.
        def add_style_rule_to_form(form_data)
          return unless option?(:style_rule)

          rule = delete_option(:style_rule)
          style_id = rule.is_a?(DeepL::Resources::StyleRule) ? rule.style_id : rule
          form_data.push(['style_id', style_id.to_s])
        end

        # Serializes the `translation_memory` option and appends it to the form data as a
        # `translation_memory_id` field. Mirrors text translation: the `translation_memory`
        # option accepts either a translation memory ID string or a
        # `DeepL::Resources::TranslationMemory` object.
        def add_translation_memory_to_form(form_data)
          return unless option?(:translation_memory)

          tm = delete_option(:translation_memory)
          tm_id = tm.is_a?(DeepL::Resources::TranslationMemory) ? tm.translation_memory_id : tm
          form_data.push(['translation_memory_id', tm_id.to_s])
        end

        # Serializes the `translation_memory_threshold` option (integer 0-100) and appends it to
        # the form data as a `translation_memory_threshold` field, mirroring text translation.
        def add_translation_memory_threshold_to_form(form_data)
          return unless option?(:translation_memory_threshold)

          threshold = delete_option(:translation_memory_threshold)
          form_data.push(['translation_memory_threshold', threshold.to_s])
        end

        def add_supported_options_to_form(form_data)
          SUPPORTED_OPTIONS.each do |option_name|
            option_value = option(option_name)
            form_data.push([option_name, option_value]) unless option_value.nil?
          end
        end

        def build_doc_handle(request, response)
          parsed_response = JSON.parse(response.body)
          Resources::DocumentHandle.new(parsed_response['document_id'],
                                        parsed_response['document_key'], request, response)
        end

        def path
          'document'
        end
      end
    end
  end
end
