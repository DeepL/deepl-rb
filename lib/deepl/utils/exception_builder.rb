# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    class ExceptionBuilder
      attr_reader :request, :response

      def self.error_class_from_response_code(code) # rubocop:disable Metrics/CyclomaticComplexity
        case code
        when 400 then Exceptions::BadRequest
        when 401, 403 then Exceptions::AuthorizationFailed
        when 404 then Exceptions::NotFound
        when 413 then Exceptions::RequestEntityTooLarge
        when 429 then Exceptions::LimitExceeded
        when 456 then Exceptions::QuotaExceeded
        when 500..599 then Exceptions::ServerError
        else Exceptions::RequestError
        end
      end

      def initialize(response, request = nil)
        @response = response
        @request = request
      end

      def build
        error_class = self.class.error_class_from_response_code(response.code.to_i)
        error_class.new(response, request)
      end
    end
  end
end
