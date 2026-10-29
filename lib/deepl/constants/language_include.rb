# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Constants
    # Values of the +include+ option of +DeepL::Client#get_languages_for_resource+. Other strings
    # are accepted and sent unchanged.
    class LanguageInclude < BaseConstant
      # Also return beta languages and features.
      BETA = 'beta'
      # Also return features that rely on third-party providers.
      EXTERNAL = 'external'
    end
  end
end
