# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class Entries < Base
        include Helpers

        attr_reader :id, :source_lang, :target_lang

        def initialize(api, id, source_lang, target_lang, options = {})
          super(api, options)
          @id = glossary_id(id)
          @source_lang = source_lang
          @target_lang = target_lang
        end

        def request
          build_entries(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def get_request # rubocop:disable Naming/AccessorMethodName
          http_headers = add_json_content_type(headers)
          Net::HTTP::Get.new(uri.request_uri, http_headers)
        end

        # The API wraps the dictionary in a list, which is empty if the glossary has no
        # dictionary for the language pair.
        def build_entries(request, response)
          dictionary = (JSON.parse(response.body)['dictionaries'] || []).first
          if dictionary.nil?
            raise Exceptions::NotFound.new(
              response, request,
              "Glossary #{id} has no dictionary for #{source_lang} -> #{target_lang}"
            )
          end

          Resources::MultilingualGlossaryDictionaryEntries.from_response(
            dictionary, request, response
          )
        end

        def uri
          @uri ||= begin
            base_uri = URI("#{host}/v3/#{path}")
            base_uri.query = encode_query(source_lang: source_lang, target_lang: target_lang)
            base_uri
          end
        end

        def path
          glossary_path(id, 'entries')
        end
      end
    end
  end
end
