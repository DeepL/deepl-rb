# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      class Destroy < Base
        include Helpers

        attr_reader :id

        def initialize(api, id)
          super(api)
          @id = spoken_terms_id(id)
        end

        def request
          execute_request_with_retries(delete_request)
          nil
        end

        def to_s
          "DELETE #{uri.request_uri}"
        end

        private

        def path
          spoken_terms_path(id)
        end
      end
    end
  end
end
