# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class RequestError < Error
      attr_reader :request, :response

      def initialize(response, request = nil)
        super()
        @response = response
        @request = request
        @http_status_code = response.code.to_i if response.respond_to?(:code)
      end

      def to_s
        message = body_message
        status = "HTTP status #{http_status_code}"
        message ? "Request failed with #{status}: #{message}" : "Request failed with #{status}."
      end

      private

      # The +message+ of a JSON object body, else the raw body; +nil+ for an empty body.
      def body_message
        body = response&.body
        return nil if body.nil? || body.to_s.strip.empty?

        data = JSON.parse(body)
        data.is_a?(Hash) && data['message'].is_a?(String) ? data['message'] : body
      rescue JSON::ParserError
        body
      end
    end
  end
end
