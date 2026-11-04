# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Glossary
      # Creates a v2 glossary from entries that are already encoded as TSV or CSV.
      class Create < DeepL::Requests::Base
        attr_reader :name, :source_lang, :target_lang, :entries, :entries_format

        def initialize(api, name, source_lang, target_lang, entries, entries_format, options = {}) # rubocop:disable Metrics/ParameterLists
          super(api, options)
          raise ArgumentError, 'Glossary name must not be empty' if name.to_s.empty?

          @name = name
          # v2 glossaries are not regional: EN-GB is sent as EN.
          @source_lang = source_lang.to_s.split('-').first.upcase
          @target_lang = target_lang.to_s.split('-').first.upcase
          @entries = entries
          @entries_format = entries_format
        end

        def request
          build_glossary(*execute_request_with_retries(post_request(payload)))
        end

        def details
          "HTTP Headers: #{loggable_headers}\nPayload #{payload}"
        end

        def to_s
          "POST #{uri.request_uri}"
        end

        private

        # A repeated creation request could create a second resource.
        def retry_only_unprocessed?
          true
        end

        def payload
          { name: name, source_lang: source_lang, target_lang: target_lang, entries: entries,
            entries_format: entries_format }
        end

        def build_glossary(request, response)
          Resources::Glossary.new(JSON.parse(response.body), request, response)
        end

        def path
          'glossaries'
        end
      end
    end
  end
end
