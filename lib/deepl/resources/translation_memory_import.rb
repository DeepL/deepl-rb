# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    ##
    # A newly created translation memory import job. The TMX file must be uploaded to
    # `upload_url` before `expires_at`, processing starts once the upload is detected.

    class TranslationMemoryImport < Base
      attr_reader :job_id, :upload_url, :expires_at

      def initialize(translation_memory_import, *args)
        super(*args)
        @job_id = translation_memory_import['job_id']
        @upload_url = translation_memory_import['upload_url']
        @expires_at = Utils::TimeParser.parse_optional_time(
          translation_memory_import['expires_at']
        )
      end

      def to_s
        "TranslationMemoryImport: ID: #{job_id}"
      end
    end
  end
end
