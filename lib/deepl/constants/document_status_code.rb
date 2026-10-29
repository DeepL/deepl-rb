# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Constants
    # Values of +DeepL::Resources::DocumentTranslationStatus#status+. The status stays a plain
    # string, so a value the API adds later is kept as it is.
    class DocumentStatusCode < BaseConstant
      QUEUED = 'queued'
      TRANSLATING = 'translating'
      DONE = 'done'
      ERROR = 'error'
    end
  end
end
