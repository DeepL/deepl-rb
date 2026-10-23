# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      class List < Base
        include Helpers

        def request
          build_spoken_terms_list(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_spoken_terms_list(request, response)
          data = JSON.parse(response.body)
          (data['spoken_terms'] || []).map do |spoken_terms|
            Resources::SpokenTerms.new(spoken_terms, request, response)
          end
        end

        def path
          'spoken-terms'
        end
      end
    end
  end
end
