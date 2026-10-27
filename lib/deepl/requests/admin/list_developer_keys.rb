# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Admin
      class ListDeveloperKeys < Base
        def request
          request, response = execute_request_with_retries(get_request)
          keys = JSON.parse(response.body)
          raise DeepL::Exceptions::Error, 'Developer key list response is not a JSON array' unless
            keys.is_a?(Array)

          keys.select { |key| usable_developer_key?(key) }
              .map { |key| Resources::DeveloperKey.new(key, request, response) }
        end

        private

        def path
          'admin/developer-keys'
        end
      end
    end
  end
end
