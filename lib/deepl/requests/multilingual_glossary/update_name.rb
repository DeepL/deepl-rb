# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class UpdateName < Base
        attr_reader :id, :name

        def initialize(api, id, name, options = {})
          super(api, options)
          @id = id
          @name = name
        end

        def request
          payload = { name: name }
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
