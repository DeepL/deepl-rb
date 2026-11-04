# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class Create < Base
        include Helpers

        attr_reader :name, :dictionaries

        def initialize(api, name, dictionaries, options = {})
          super(api, options)
          raise ArgumentError, 'Glossary name must not be empty' if name.to_s.empty?
          raise ArgumentError, 'Glossary needs at least one dictionary' if dictionaries.to_a.empty?

          @name = name
          @dictionaries = dictionaries.map { |dictionary| dictionary_payload(dictionary) }
        end

        def request
          payload = { name: name, dictionaries: dictionaries }
          build_glossary(*execute_request_with_retries(post_request(payload)))
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        # A repeated creation request could create a second resource.
        def retry_only_unprocessed?
          true
        end

        def path
          'glossaries'
        end
      end
    end
  end
end
