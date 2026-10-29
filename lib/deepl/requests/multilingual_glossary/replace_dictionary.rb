# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class ReplaceDictionary < Base
        include Helpers

        attr_reader :id, :dictionary

        def initialize(api, id, dictionary, options = {})
          super(api, options)
          @id = glossary_id(id)
          @dictionary = dictionary_payload(dictionary)
        end

        def request
          build_dictionary(*execute_request_with_retries(put_request(dictionary)))
        end

        def to_s
          "PUT #{uri.request_uri}"
        end

        private

        def build_dictionary(request, response)
          data = JSON.parse(response.body)
          Resources::MultilingualGlossaryDictionary.new(data, request, response)
        end

        def path
          glossary_path(id, 'dictionaries')
        end
      end
    end
  end
end
