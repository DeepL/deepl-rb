# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module SpokenTerms
      # Encoding shared by the spoken terms requests. The API sends and returns the terms of a
      # language as one newline-separated string; the SDK exposes them as an array.
      module Helpers
        private

        def spoken_terms_id(spoken_terms)
          return spoken_terms.spoken_terms_id if spoken_terms.is_a?(DeepL::Resources::SpokenTerms)

          spoken_terms.to_s
        end

        def spoken_terms_path(id, suffix = nil)
          ["spoken-terms/#{id}", suffix].compact.join('/')
        end

        def entries_to_string(entries)
          entries.map { |entry| Utils::TermValidator.validate!(entry) }.join("\n")
        end

        def entries_from_string(entries)
          (entries || '').split("\n").reject(&:empty?)
        end

        def term_lists_payload(term_lists)
          term_lists.map { |term_list| term_list_payload(term_list) }
        end

        # Accepts a SpokenTermsEntries object or a hash with +:lang+ and +:entries+.
        def term_list_payload(term_list)
          lang, entries = if term_list.is_a?(DeepL::Resources::SpokenTermsEntries)
                            [term_list.lang, term_list.entries]
                          else
                            [term_list[:lang] || term_list['lang'],
                             term_list[:entries] || term_list['entries']]
                          end
          { lang: lang, entries: entries_to_string(entries) }
        end

        def build_spoken_terms(request, response)
          Resources::SpokenTerms.new(JSON.parse(response.body), request, response)
        end

        def uri
          @uri ||= URI("#{host}/v3/#{path}")
        end

        # GET and DELETE send no body.
        def get_request # rubocop:disable Naming/AccessorMethodName
          Net::HTTP::Get.new(uri.request_uri, add_json_content_type(headers))
        end

        def delete_request
          Net::HTTP::Delete.new(uri.request_uri, add_json_content_type(headers))
        end
      end
    end
  end
end
