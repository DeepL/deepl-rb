# Copyright 2021 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    class Languages < Base
      SUPPORTED_TYPES = %w[source target].freeze

      def initialize(api, options = {})
        super
        @type = (delete_option(:type) || :source).to_s
        return if SUPPORTED_TYPES.include?(@type)

        raise ArgumentError, "Unsupported `type` option: #{@type.inspect} " \
                             "(supported: #{SUPPORTED_TYPES.join(', ')})"
      end

      def request
        build_languages(*execute_request_with_retries(get_request))
      end

      def to_s
        "GET #{uri.request_uri}"
      end

      private

      def target?
        @type == 'target'
      end

      def build_languages(request, response)
        data = JSON.parse(response.body)
        usable_key = target? ? 'usable_as_target' : 'usable_as_source'
        data.select { |language| language[usable_key] }.map do |language|
          supports_formality = target? ? language.fetch('features', {}).to_h.key?('formality') : nil
          Resources::Language.new(language['lang'].upcase, language['name'], supports_formality,
                                  request, response)
        end
      end

      def uri
        @uri ||= URI("#{host}/v3/#{path}?resource=translate_text")
      end

      def get_request # rubocop:disable Naming/AccessorMethodName
        Net::HTTP::Get.new(uri.request_uri, add_json_content_type(headers))
      end

      def path
        'languages'
      end
    end
  end
end
