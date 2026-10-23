# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      class Create < Base
        include Helpers

        attr_reader :name, :term_lists

        def initialize(api, name, term_lists, options = {})
          super(api, options)
          @name = name
          @term_lists = term_lists
        end

        def request
          payload = { name: name, term_lists: term_lists_payload(term_lists) }
          build_spoken_terms(*execute_request_with_retries(post_request(payload)))
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        def path
          'spoken-terms'
        end
      end
    end
  end
end
