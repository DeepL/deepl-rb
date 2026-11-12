# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleRule
      class Create < Base
        include Helpers

        accepts_options :configured_rules, :custom_instructions

        def initialize(api, name, language, options = {})
          super(api, options)
          check_non_empty!(name: name, language: language)
          @name = name
          @language = language
          @configured_rules = delete_option(:configured_rules)
          @custom_instructions = delete_option(:custom_instructions)
          validate_instruction_languages!(@custom_instructions)
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

        # A repeated creation request could create a second resource.
        def retry_only_unprocessed?
          true
        end

        # +custom_instructions+ is sent as given; only an empty +source_language+ is rejected.
        def validate_instruction_languages!(instructions)
          return unless instructions.is_a?(Array)

          instructions.each do |instruction|
            next unless instruction.is_a?(Hash)

            validate_language!('source_language',
                               instruction[:source_language] || instruction['source_language'],
                               optional: true)
          end
        end

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
