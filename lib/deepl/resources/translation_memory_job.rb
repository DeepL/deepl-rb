# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Resources
    ##
    # The outcome of a translation memory import or export job.

    class TranslationMemoryJobResult
      STATUS_AWAITING_INPUT = 'awaiting_input'
      STATUS_PROCESSING = 'processing'
      STATUS_COMPLETED = 'completed'
      STATUS_DOWNLOADED = 'downloaded'
      STATUS_FAILED = 'failed'
      STATUS_EXPIRED = 'expired'

      attr_reader :status, :required_action, :download_url, :expires_at, :error_message,
                  :translation_memory_id, :skipped_segment_count

      def initialize(result)
        status_metadata = result['status_metadata'] || {}
        error = result['error'] || {}

        @status = result['status']
        @required_action = status_metadata['required_action']
        @download_url = result['download_url']
        @expires_at = Utils::TimeParser.parse_optional_time(result['expires_at'])
        @error_message = error['message']
        @translation_memory_id = result['translation_memory_id']
        @skipped_segment_count = result['skipped_segment_count']
      end

      ##
      # Checks if the job terminated. Note that this could be due to an error as well, but means
      # no further waiting is necessary.
      #
      # @return [true] if so

      def finished?
        [STATUS_COMPLETED, STATUS_DOWNLOADED, STATUS_FAILED, STATUS_EXPIRED].include?(status)
      end

      ##
      # Checks if the job is still waiting for the TMX file to be uploaded. Note that the API
      # detects an upload asynchronously, so a job keeps reporting this status for a while after
      # its file has been uploaded.
      #
      # @return [true] if so

      def awaiting_input?
        status == STATUS_AWAITING_INPUT
      end

      ##
      # Checks if there was an error during the job, including it having expired.
      #
      # @return [true] if so

      def error?
        [STATUS_FAILED, STATUS_EXPIRED].include?(status)
      end

      def to_s
        "TranslationMemoryJobResult: Status: #{status} - Error message: #{error_message}"
      end
    end

    ##
    # Status of a translation memory import or export job. The API returns exactly one result.

    class TranslationMemoryJob < Base
      OPERATION_IMPORT = 'import'
      OPERATION_EXPORT = 'export'

      attr_reader :job_id, :product, :operation, :creation_time, :updated_time, :results,
                  :translation_memory_id, :display_name, :source_content_type,
                  :source_content_length

      def initialize(job, *args)
        super(*args)
        extract_basic_fields(job)
        extract_parameters(job)
        @results = (job['results'] || []).map { |result| TranslationMemoryJobResult.new(result) }
      end

      ##
      # The single result of the job, or nil if the API returned none.
      #
      # @return [DeepL::Resources::TranslationMemoryJobResult, nil]

      def result
        results.first
      end

      def status
        result&.status
      end

      def finished?
        result ? result.finished? : false
      end

      def awaiting_input?
        result ? result.awaiting_input? : false
      end

      def error?
        result ? result.error? : false
      end

      def error_message
        result&.error_message
      end

      def to_s
        "TranslationMemoryJob: #{operation} - ID: #{job_id} - Status: #{status}"
      end

      private

      def extract_basic_fields(job)
        @job_id = job['job_id']
        @product = job['product']
        @operation = job['operation']
        @creation_time = Utils::TimeParser.parse_optional_time(job['creation_time'])
        @updated_time = Utils::TimeParser.parse_optional_time(job['updated_time'])
      end

      def extract_parameters(job)
        parameters = job['parameters'] || {}
        source_file = job['source_file'] || {}

        @translation_memory_id = parameters['translation_memory_id']
        @display_name = parameters['display_name']
        @source_content_type = source_file['content_type']
        @source_content_length = source_file['content_length']
      end
    end
  end
end
