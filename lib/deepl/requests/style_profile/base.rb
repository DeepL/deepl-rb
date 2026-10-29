# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module StyleProfile
      # Common behaviour of the style profile requests: served under +v3+, with the ID escaped
      # into the path and GET/DELETE sent without a body.
      class Base < DeepL::Requests::Base
        COMPONENT_ID_FIELDS = %i[glossary_ids style_rule_ids translation_memory_ids].freeze

        private

        def style_profile_id(style_profile)
          id = if style_profile.is_a?(DeepL::Resources::StyleProfile)
                 style_profile.style_profile_id.to_s
               else
                 style_profile.to_s
               end
          raise ArgumentError, 'style_profile_id must not be empty' if id.empty?

          id
        end

        def escaped_id
          URI.encode_www_form_component(id).gsub('+', '%20')
        end

        # Adds the optional fields that are set. nil is not sent; '' and [] are sent as given.
        def optional_fields_payload(fields)
          fields.each_with_object({}) do |(key, value), payload|
            next if value.nil?

            payload[key] = COMPONENT_ID_FIELDS.include?(key) ? component_ids(value) : value
          end
        end

        # Replaces resource objects in a component list by their IDs; other entries are kept.
        def component_ids(value)
          return value unless value.is_a?(Array)

          value.map { |component| component_id(component) }
        end

        def component_id(component)
          case component
          when DeepL::Resources::Glossary, DeepL::Resources::MultilingualGlossary then component.id
          when DeepL::Resources::StyleRule then component.style_id
          when DeepL::Resources::TranslationMemory then component.translation_memory_id
          else component
          end
        end

        def build_style_profile(request, response)
          Resources::StyleProfile.new(JSON.parse(response.body), request, response)
        end

        def uri
          @uri ||= begin
            base_uri = URI("#{host}/v3/#{path}")
            query_string = URI.encode_www_form(query_params)
            base_uri.query = query_string unless query_string.empty?
            base_uri
          end
        end

        def query_params
          {}
        end

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
