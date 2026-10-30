# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      class Entries < Base
        include Helpers

        attr_reader :id, :lang

        def initialize(api, id, lang)
          super(api)
          @id = spoken_terms_id(id)
          @lang = lang
        end

        def request
          build_entries(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_entries(request, response)
          data = JSON.parse(response.body)
          Resources::SpokenTermsEntries.new(data['lang'], entries_from_string(data['entries']),
                                            request, response)
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}?#{encode_query(lang: lang)}")
        end

        def path
          spoken_terms_path(id, 'entries')
        end
      end
    end
  end
end
