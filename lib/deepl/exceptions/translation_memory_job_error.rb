# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    ##
    # Any failure of DeepL::Client#import_translation_memory_from_filepath or
    # #export_translation_memory_to_filepath except a missing input file. The failure being
    # wrapped is the +cause+.
    class TranslationMemoryJobError < Error
      # @return [DeepL::Resources::TranslationMemoryJob, nil] The job once it was created, with
      #   the last status the library received, +nil+ if the failure happened before. Use its
      #   +job_id+ to query or resume the job.
      attr_reader :job

      # +error+ is the failure being wrapped; the HTTP status and retryability of a DeepL error
      # are copied from it.
      def initialize(message, job, error = nil)
        deepl_error = error.is_a?(Error) ? error : nil
        super(message, http_status_code: deepl_error&.http_status_code,
                       should_retry: deepl_error&.should_retry? || false)
        @job = job
      end
    end
  end
end
