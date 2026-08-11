# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    ##
    # A translation memory export job. Poll the job until it is finished to obtain the download
    # URL of the exported TMX file.

    class TranslationMemoryExport < Base
      attr_reader :job_id, :translation_memory_id

      def initialize(translation_memory_export, reused_existing, *args)
        super(*args)
        parameters = translation_memory_export['parameters'] || {}
        @job_id = translation_memory_export['job_id']
        @translation_memory_id = parameters['translation_memory_id']
        @reused_existing = reused_existing
      end

      ##
      # Checks if the API reused a previously completed export instead of starting a new one.
      #
      # @return [true] if so

      def reused_existing?
        @reused_existing
      end

      def to_s
        "TranslationMemoryExport: ID: #{job_id}"
      end
    end
  end
end
