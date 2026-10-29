# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class NotFound < RequestError
      # @param [String, nil] message Replaces the API's message, for a not-found condition the
      #   SDK detects in a successful response.
      def initialize(response, request = nil, message = nil)
        super(response, request)
        @message = message
      end

      def to_s
        (@message || body_message).to_s
      end
    end
  end
end
