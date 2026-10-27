# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Admin
      ##
      # Sends a PUT to +admin/developer-keys/<action>+. The payload is sent as is, so +nil+
      # values are serialized as explicit JSON nulls.
      class UpdateDeveloperKey < Base
        def initialize(api, action, payload)
          super(api)
          @action = action
          @payload = payload
        end

        def request
          build_developer_key(*execute_request_with_retries(put_request(@payload.dup)))
        end

        private

        def http_method
          'PUT'
        end

        def path
          "admin/developer-keys/#{@action}"
        end
      end
    end
  end
end
