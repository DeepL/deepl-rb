# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      class DestroyTermList < Base
        include Helpers

        attr_reader :id, :lang

        def initialize(api, id, lang, options = {})
          super(api, options)
          @id = spoken_terms_id(id)
          @lang = lang
        end

        def request
          execute_request_with_retries(delete_request)
          lang
        end

        def to_s
          "DELETE #{uri.request_uri}"
        end

        private

        def delete_request
          Net::HTTP::Delete.new(uri.request_uri, add_json_content_type(headers))
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}?#{URI.encode_www_form(lang: lang)}")
        end

        def path
          "spoken-terms/#{id}/term-lists"
        end
      end
    end
  end
end
