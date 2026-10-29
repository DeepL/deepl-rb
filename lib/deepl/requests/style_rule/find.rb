# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleRule
      class Find < Base
        include Helpers

        def initialize(api, style_id, options = {})
          super(api, options)
          @style_id = style_rule_id(style_id)
        end

        def request
          build_style_rule(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_style_rule(request, response)
          data = JSON.parse(response.body)
          DeepL::Resources::StyleRule.new(data, request, response)
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}")
        end

        def path
          style_rule_path(@style_id)
        end
      end
    end
  end
end
