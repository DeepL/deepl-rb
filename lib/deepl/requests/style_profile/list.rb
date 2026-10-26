# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleProfile
      class List < Base
        SUPPORTED_OPTIONS = %w[page page_size].freeze

        def request
          build_style_profile_list(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_style_profile_list(request, response)
          profiles = JSON.parse(response.body)['style_profiles']
          return [] unless profiles.is_a?(Array)

          profiles.grep(Hash).map do |profile|
            Resources::StyleProfile.new(profile, request, response)
          end
        end

        def query_params
          SUPPORTED_OPTIONS.each_with_object({}) do |option_name, params|
            params[option_name] = option(option_name).to_s if option?(option_name)
          end
        end

        def path
          'style_profiles'
        end
      end
    end
  end
end
