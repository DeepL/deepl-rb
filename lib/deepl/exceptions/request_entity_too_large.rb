# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class RequestEntityTooLarge < RequestError
      def to_s
        with_body_message('The request size has reached the supported limit.')
      end
    end
  end
end
