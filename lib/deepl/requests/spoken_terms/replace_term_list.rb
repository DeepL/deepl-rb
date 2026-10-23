# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      class ReplaceTermList < Base
        include Helpers

        attr_reader :id, :lang, :entries

        def initialize(api, id, lang, entries, options = {})
          super(api, options)
          @id = spoken_terms_id(id)
          @lang = lang
          @entries = entries
        end

        def request
          payload = { lang: lang, entries: entries_to_string(entries) }
          build_term_list(*execute_request_with_retries(put_request(payload)))
        end

        def to_s
          "PUT #{uri.request_uri}"
        end

        private

        def build_term_list(request, response)
          Resources::SpokenTermsList.new(JSON.parse(response.body), request, response)
        end

        def path
          "spoken-terms/#{id}/term-lists"
        end
      end
    end
  end
end
