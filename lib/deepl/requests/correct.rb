# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    class Correct < Base
      include WriteImprovements

      attr_reader :text, :target_lang

      def initialize(api, text, target_lang = nil, options = {}, additional_headers = {})
        super(api, options, additional_headers)
        @text = text
        @target_lang = target_lang
        validate_text!
      end

      def request
        payload = { text: text_arrayified }
        payload[:target_lang] = target_lang unless target_lang.nil?
        build_texts(*execute_request_with_retries(post_request(payload)))
      end

      def details
        "HTTP Headers: #{loggable_headers}\nPayload #{{ text: text, target_lang: target_lang }}"
      end

      def to_s
        "POST #{uri.request_uri}"
      end

      private

      def text_arrayified
        text.is_a?(Array) ? text : [text]
      end

      def validate_text!
        return unless text_arrayified.empty? || text_arrayified.any? { |t| t.to_s.empty? }

        raise ArgumentError,
              '`text` must be a non-empty string or a non-empty array of non-empty strings'
      end

      def build_texts(request, response)
        texts = build_improvements(text_arrayified.size, request, response)
        text.is_a?(Array) ? texts : texts.first
      end

      def path
        'write/correct'
      end
    end
  end
end
