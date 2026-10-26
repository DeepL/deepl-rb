# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleProfile
      class Update < Base
        attr_reader :id, :fields

        def initialize(api, id, fields, options = {})
          super(api, options)
          @id = style_profile_id(id)
          @fields = fields
        end

        def request
          payload = optional_fields_payload(fields)
          build_style_profile(*execute_request_with_retries(patch_request(payload)))
        end

        def to_s
          "PATCH #{uri.request_uri}"
        end

        private

        def path
          "style_profiles/#{escaped_id}"
        end
      end
    end
  end
end
