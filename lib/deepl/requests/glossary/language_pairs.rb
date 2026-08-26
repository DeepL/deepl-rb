# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Glossary
      class LanguagePairs < Base
        def initialize(api, options = {})
          super
        end

        def request
          build_language_pair_list(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_language_pair_list(request, response)
          data = JSON.parse(response.body)
          sources = langs_where(data, 'usable_as_source')
          targets = langs_where(data, 'usable_as_target')

          sources.product(targets).each_with_object([]) do |(source, target), pairs|
            next if source == target

            pairs << Resources::LanguagePair.new(source, target, request, response)
          end
        end

        def langs_where(data, usable_key)
          data.select { |language| language[usable_key] }.map { |language| language['lang'] }
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}?resource=glossary")
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
end
