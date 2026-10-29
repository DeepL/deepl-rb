# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleRule
      class Create < Base
        def initialize(api, name, language, options = {})
          super(api, options.dup)
          @name = name
          @language = language
          @configured_rules = delete_option(:configured_rules)
          @custom_instructions = delete_option(:custom_instructions)
        end

        def request
          payload = { name: @name, language: @language }
          payload[:configured_rules] = @configured_rules if @configured_rules
          payload[:custom_instructions] = @custom_instructions if @custom_instructions
          build_style_rule(*execute_request_with_retries(post_request(payload)))
        end

        def to_s
          "POST #{uri.request_uri}"
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
          'style_rules'
        end
      end
    end
  end
end
