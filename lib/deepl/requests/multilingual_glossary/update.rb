# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class Update < Base
        include Helpers

        attr_reader :id, :name, :dictionaries

        def initialize(api, id, name, dictionaries, options = {})
          super(api, options)
          @id = glossary_id(id)
          @name = name
          @dictionaries = dictionaries&.map { |dictionary| dictionary_payload(dictionary) }
        end

        def request
          payload = {}
          payload[:name] = name unless name.nil?
          payload[:dictionaries] = dictionaries unless dictionaries.nil?
          build_glossary(*execute_request_with_retries(patch_request(payload)))
        end

        def to_s
          "PATCH #{uri.request_uri}"
        end

        private

        def path
          glossary_path(id)
        end
      end
    end
  end
end
