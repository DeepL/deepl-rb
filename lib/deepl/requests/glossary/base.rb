# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Glossary
      # A request for one v2 glossary, given as its ID or a Resources::Glossary.
      class Base < DeepL::Requests::Base
        attr_reader :id

        def initialize(api, glossary)
          super(api, {})
          @id = glossary.is_a?(DeepL::Resources::Glossary) ? glossary.id : glossary.to_s
        end

        def to_s
          "#{self.class::METHOD} #{uri.request_uri}"
        end

        private

        def glossary_path(suffix = nil)
          ["glossaries/#{escape_path_segment(id)}", suffix].compact.join('/')
        end
      end
    end
  end
end
