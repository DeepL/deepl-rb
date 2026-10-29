# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      class Update < Base
        include Helpers

        attr_reader :id, :name, :term_lists

        def initialize(api, id, name, term_lists, options = {})
          super(api, options)
          @id = spoken_terms_id(id)
          @name = name
          @term_lists = term_lists
        end

        def request
          payload = {}
          payload[:name] = name unless name.nil?
          payload[:term_lists] = term_lists_payload(term_lists) unless term_lists.nil?
          build_spoken_terms(*execute_request_with_retries(patch_request(payload)))
        end

        def to_s
          "PATCH #{uri.request_uri}"
        end

        private

        def path
          spoken_terms_path(id)
        end
      end
    end
  end
end
