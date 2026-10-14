# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class Create < Base
        include EntriesSerializer

        attr_reader :name, :dictionaries

        def initialize(api, name, dictionaries, options = {})
          super(api, options)
          @name = name
          @dictionaries = dictionaries.map { |dictionary| build_dictionary(dictionary) }
        end

        def request
          payload = { name: name, dictionaries: dictionaries }
          build_glossary(*execute_request_with_retries(post_request(payload)))
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        def build_dictionary(dictionary)
          source_lang = dictionary[:source_lang] || dictionary['source_lang']
          target_lang = dictionary[:target_lang] || dictionary['target_lang']
          entries = dictionary[:entries] || dictionary['entries']
          entries_format = dictionary[:entries_format] || dictionary['entries_format'] || 'tsv'
          {
            source_lang: source_lang,
            target_lang: target_lang,
            entries: entries_to_string(entries),
            entries_format: entries_format
          }
        end

        def build_glossary(request, response)
          data = JSON.parse(response.body)
          Resources::MultilingualGlossary.new(data, request, response)
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}")
        end

        def path
          'glossaries'
        end
      end
    end
  end
end
