# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class Entries < Base
        attr_reader :id, :source_lang, :target_lang

        def initialize(api, id, source_lang, target_lang, options = {})
          super(api, options)
          @id = id
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

        def build_entries(request, response)
          data = JSON.parse(response.body)
          (data['dictionaries'] || []).map do |dictionary|
            Resources::MultilingualGlossaryDictionaryEntries.new(dictionary, request, response)
          end
        end

        def uri
          @uri ||= begin
            base_uri = URI("#{host}/v3/#{path}")
            base_uri.query = URI.encode_www_form(source_lang: source_lang, target_lang: target_lang)
            base_uri
          end
        end

        def path
          "glossaries/#{id}/entries"
        end
      end
    end
  end
end
