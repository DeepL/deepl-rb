# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class Find < Base
        attr_reader :id

        def initialize(api, id, options = {})
          super(api, options)
          @id = id
        end

        def request
          build_glossary(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
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
