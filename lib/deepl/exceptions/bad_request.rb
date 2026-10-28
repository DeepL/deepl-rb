# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class BadRequest < RequestError
      def to_s
        body_message.to_s
      end
    end
  end
end
