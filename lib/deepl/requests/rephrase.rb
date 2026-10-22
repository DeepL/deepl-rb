# Copyright 2025 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    class Rephrase < Base
      attr_reader :text, :target_lang, :writing_style, :tone

      def initialize(api, text, target_lang = nil, writing_style = nil, tone = nil, options = {}, # rubocop:disable Metrics/ParameterLists
                     additional_headers = {})
        super(api, options, additional_headers)
        @text = text
        @target_lang = target_lang
        @writing_style = writing_style
        @tone = tone
      end

      def request # rubocop:disable Metrics/AbcSize
        text_arrayified = text.is_a?(Array) ? text : [text]
        payload = { text: text_arrayified }
        payload[:target_lang] = target_lang unless target_lang.nil?
        payload[:writing_style] = writing_style unless writing_style.nil?
        payload[:tone] = tone unless tone.nil?
        build_texts(*execute_request_with_retries(post_request(payload)))
      end

      def details
        "HTTP Headers: #{loggable_headers}\nPayload #{{ text: text, target_lang: target_lang,
                                                        writing_style: writing_style, tone: tone }}"
      end

      def to_s
        "POST #{uri.request_uri}"
      end

      private

      def build_texts(request, response)
        data = JSON.parse(response.body)

        texts = data['improvements'].map do |improvement|
          Resources::Text.new(improvement['text'], improvement['detected_source_language'], nil,
                              request, response)
        end

        texts.size == 1 ? texts.first : texts
      end

      def path
        'write/rephrase'
      end
    end
  end
end
