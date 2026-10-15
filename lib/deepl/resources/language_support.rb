# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module DeepL
  module Resources
    # Support level of a single feature of a language for a resource.
    class LanguageFeature
      attr_reader :status

      def initialize(status)
        @status = status
      end

      def to_s
        status.to_s
      end
    end

    # A language supported by a DeepL API resource, as returned by `DeepL.languages_for_resource`.
    class LanguageSupport < Base
      attr_reader :code, :name, :status, :features

      def initialize(language, *args)
        super(*args)

        @code = language['lang']
        @name = language['name']
        @status = language['status']
        @usable_as_source = language['usable_as_source'] ? true : false
        @usable_as_target = language['usable_as_target'] ? true : false
        @features = (language['features'] || {}).to_h.transform_values do |feature|
          LanguageFeature.new(feature.to_h['status'])
        end
      end

      def to_s
        "#{name} (#{code})"
      end

      def usable_as_source?
        @usable_as_source
      end

      def usable_as_target?
        @usable_as_target
      end

      # Returns true if this language supports the given feature (e.g. 'formality').
      def supports?(feature)
        features.key?(feature.to_s)
      end
    end
  end
end
