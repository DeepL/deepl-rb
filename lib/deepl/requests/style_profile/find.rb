# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleProfile
      class Find < Base
        attr_reader :id

        def initialize(api, id, options = {})
          super(api, options)
          @id = style_profile_id(id)
        end

        def request
          build_style_profile(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def path
          "style_profiles/#{escaped_id}"
        end
      end
    end
  end
end
