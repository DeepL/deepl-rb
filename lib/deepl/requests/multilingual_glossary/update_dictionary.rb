# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class UpdateDictionary < Base
        include EntriesSerializer

        attr_reader :id, :source_lang, :target_lang, :entries, :entries_format

        def initialize(api, id, source_lang, target_lang, entries, options = {})
          super(api, options)
          @id = id
          @source_lang = source_lang
          @target_lang = target_lang
          @entries_format = delete_option(:entries_format) || 'tsv'
          @entries = entries
        end

        def request
          payload = {
            dictionaries: [{
              source_lang: source_lang, target_lang: target_lang,
              entries: entries_to_string(entries), entries_format: entries_format
            }]
          }
          build_glossary(*execute_request_with_retries(patch_request(payload)))
        end

        def to_s
          "PATCH #{uri.request_uri}"
        end

        private

        def build_glossary(request, response)
          data = JSON.parse(response.body)
          Resources::MultilingualGlossary.new(data, request, response)
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}")
        end

        def path
          "glossaries/#{id}"
        end
      end
    end
  end
end
