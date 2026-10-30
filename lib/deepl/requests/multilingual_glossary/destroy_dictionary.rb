# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class DestroyDictionary < Base
        include Helpers

        attr_reader :id, :source_lang, :target_lang

        def initialize(api, id, source_lang, target_lang, options = {})
          super(api, options)
          @id = glossary_id(id)
          @source_lang = source_lang
          @target_lang = target_lang
        end

        def request
          execute_request_with_retries(delete_request)
          nil
        end

        def to_s
          "DELETE #{uri.request_uri}"
        end

        private

        def delete_request
          http_headers = add_json_content_type(headers)
          Net::HTTP::Delete.new(uri.request_uri, http_headers)
        end

        def uri
          @uri ||= begin
            base_uri = URI("#{host}/v3/#{path}")
            base_uri.query = encode_query(source_lang: source_lang, target_lang: target_lang)
            base_uri
          end
        end

        def path
          glossary_path(id, 'dictionaries')
        end
      end
    end
  end
end
