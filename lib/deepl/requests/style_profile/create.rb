# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleProfile
      class Create < Base
        attr_reader :name, :fields

        def initialize(api, name, fields, options = {})
          super(api, options)
          @name = name
          @fields = fields
        end

        def request
          payload = { name: name }.merge(optional_fields_payload(fields))
          build_style_profile(*execute_request_with_retries(post_request(payload)))
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        def path
          'style_profiles'
        end
      end
    end
  end
end
