# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    # @api private
    # Builds the results of the write endpoints (rephrase, correct) from their response.
    module WriteImprovements
      private

      # Returns one DeepL::Resources::Text per improvement. Raises DeepL::Exceptions::Error if
      # the response has fewer improvements than +input_count+ input texts.
      def build_improvements(input_count, request, response)
        improvements = JSON.parse(response.body)['improvements']
        unless improvements.is_a?(Array) && improvements.size >= input_count
          count = improvements.is_a?(Array) ? improvements.size : 'no'
          raise Exceptions::Error, 'Unexpected response from the DeepL API: expected ' \
                                   "#{input_count} improvements, got #{count}"
        end

        improvements.map do |improvement|
          Resources::Text.new(improvement['text'], improvement['detected_source_language'], nil,
                              request, response)
        end
      end
    end
  end
end
