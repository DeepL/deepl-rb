# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Resources
    # A feature supported by a DeepL API resource, as returned by `DeepL::Client#get_language_resources`.
    class ResourceFeature
      attr_reader :name

      def initialize(feature)
        @name = feature['name']
        @needs_source_support = feature['needs_source_support'] ? true : false
        @needs_target_support = feature['needs_target_support'] ? true : false
      end

      def to_s
        name
      end

      # True if the source language must support this feature for it to be available.
      def needs_source_support?
        @needs_source_support
      end

      # True if the target language must support this feature for it to be available.
      def needs_target_support?
        @needs_target_support
      end
    end

    # A DeepL API resource and the features it supports, as returned by `DeepL::Client#get_language_resources`.
    class LanguageResource < Base
      attr_reader :name, :features

      def initialize(resource, *args)
        super(*args)

        @name = resource['name']
        @features = (resource['features'] || []).to_h do |feature|
          resource_feature = ResourceFeature.new(feature)
          [resource_feature.name, resource_feature]
        end
      end

      def to_s
        name
      end

      # Returns true if this resource exposes the given feature (e.g. 'glossary').
      def supports?(feature)
        features.key?(feature.to_s)
      end
    end
  end
end
