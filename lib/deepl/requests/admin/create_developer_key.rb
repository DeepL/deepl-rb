# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Admin
      class CreateDeveloperKey < Base
        def initialize(api, label = nil, extra_body_parameters = nil)
          super(api, extra_body_parameters)
          @label = label
        end

        def request
          payload = {}
          payload[:label] = @label unless @label.nil?
          build_developer_key(*execute_request_with_retries(post_request(payload)))
        end

        private

        def http_method
          'POST'
        end

        def path
          'admin/developer-keys'
        end

        # A repeated creation request could create a second key.
        def retry_only_unprocessed?
          true
        end
      end
    end
  end
end
