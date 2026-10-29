# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Constants
    # Values of the +tag_handling_version+ option. Any other string is sent as given.
    class TagHandlingVersion < BaseConstant
      V1 = 'v1'
      V2 = 'v2'
    end
  end
end
