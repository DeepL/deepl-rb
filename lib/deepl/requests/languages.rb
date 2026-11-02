# Copyright 2021 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    class Languages < Base
      # +type+ is +:source+ or +:target+.
      def initialize(api, type)
        super(api, {})
        @type = type
      end

      def request
        build_languages(*execute_request_with_retries(get_request))
      end

      def to_s
        "GET #{uri.request_uri}"
      end

      private

      def target?
        @type == :target
      end

      def build_languages(request, response)
        data = JSON.parse(response.body)
        usable_key = target? ? 'usable_as_target' : 'usable_as_source'
        data.select { |language| language[usable_key] }.map do |language|
          build_language(language, request, response)
        end
      end

      def build_language(language, request, response)
        supports_formality = target? ? language.fetch('features', {}).to_h.key?('formality') : nil
        Resources::Language.new(language['lang'].upcase, language['name'], supports_formality,
                                request, response)
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
