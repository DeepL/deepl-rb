# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module MultilingualGlossary
      class List < Base
        def initialize(api, options = {})
          super
        end

        def request
          build_glossary_list(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_glossary_list(request, response)
          data = JSON.parse(response.body)
          data['glossaries'].map do |glossary|
            Resources::MultilingualGlossary.new(glossary, request, response)
          end
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
