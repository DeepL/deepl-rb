# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    ##
    # An invalid argument detected before any request is sent: an invalid glossary or spoken
    # terms term, or a malformed glossary TSV line.
    class ValidationError < Error
    end
  end
end
