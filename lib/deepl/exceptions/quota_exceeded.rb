# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    class QuotaExceeded < RequestError
      def to_s
        with_body_message('Quota exceeded. The character limit has been reached.')
      end
    end
  end
end
