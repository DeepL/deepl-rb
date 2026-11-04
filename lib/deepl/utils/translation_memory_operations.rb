# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    # The requests, polling and ID handling behind the translation memory methods of
    # DeepL::Client.
    # @api private
    class TranslationMemoryOperations # rubocop:disable Metrics/ClassLength
      # Time to wait between two status queries of an import or export job.
      JOB_POLLING_INTERVAL_SECONDS = 5

      def initialize(api)
        @api = api
      end

      def list(options = {})
        DeepL::Requests::TranslationMemory::List.new(@api, options).request
      end

      def find(translation_memory, options = {})
        DeepL::Requests::TranslationMemory::Find.new(
          @api, extract_translation_memory_id(translation_memory), options
        ).request
      end

      def segments(translation_memory, options = {})
        DeepL::Requests::TranslationMemory::Segments.new(
          @api, extract_translation_memory_id(translation_memory), options
        ).request
      end

      def destroy(translation_memory, options = {})
        DeepL::Requests::TranslationMemory::Destroy.new(
          @api, extract_translation_memory_id(translation_memory), options
        ).request
      end

      def create_import(file_name, content_length, content_type: nil, display_name: nil,
                        extra_body_parameters: nil)
        options = { content_type: content_type, display_name: display_name,
                    extra_body_parameters: extra_body_parameters }.compact
        DeepL::Requests::TranslationMemory::CreateImport.new(
          @api, file_name, content_length, options
        ).request
      end

      def upload_file(translation_memory_import, file_content,
                      content_type: Requests::TranslationMemory::UploadFile::DEFAULT_CONTENT_TYPE)
        DeepL::Requests::TranslationMemory::UploadFile.new(
          @api, extract_upload_url(translation_memory_import), file_content, content_type
        ).request
      end

      def create_export(translation_memory, options = {})
        DeepL::Requests::TranslationMemory::CreateExport.new(
          @api, extract_translation_memory_id(translation_memory), options
        ).request
      end

      def find_job(job, options = {})
        DeepL::Requests::TranslationMemory::FindJob.new(@api, extract_job_id(job), options).request
      end

      # Yields each status it receives, if a block is given.
      def wait_until_job_done(job, timeout_s: nil, &on_status)
        deadline = timeout_s.nil? ? nil : monotonic_time + timeout_s
        job_status = find_job(job).tap { |status| on_status&.call(status) }
        until job_status.finished?
          interval = polling_interval_until(deadline, timeout_s)
          log_job_polling(interval)
          sleep(interval)
          job_status = find_job(job).tap { |status| on_status&.call(status) }
        end
        raise_job_error(job_status) if job_status.error?

        job_status
      end

      def download_export(job, output_path)
        download_url = extract_download_url(job)
        Utils::OutputPath.check!(output_path)
        DeepL::Requests::TranslationMemory::DownloadExport.new(@api, download_url,
                                                               output_path).request
      end

      def import_from_filepath(input_file_path, display_name: nil, timeout_s: nil,
                               content_type: nil, extra_body_parameters: nil)
        check_input_file(input_file_path)
        with_job_error('import') do |progress|
          file_content = read_input_file(input_file_path)
          raise ArgumentError, "File #{input_file_path} is empty" if file_content.empty?

          created = create_import(File.basename(input_file_path), file_content.bytesize,
                                  content_type: content_type, display_name: display_name,
                                  extra_body_parameters: extra_body_parameters)
          upload_and_wait(created, file_content, content_type, timeout_s, progress)
        end
      end

      def export_to_filepath(translation_memory, output_path, timeout_s: nil)
        with_job_error('export') do |progress|
          check_output_path(output_path)
          created = create_export(translation_memory)
          progress[:job] = created_job(created.job_id, Resources::TranslationMemoryJob::OPERATION_EXPORT)
          job = wait_until_job_done(created.job_id, timeout_s: timeout_s) { progress[:job] = _1 }
          download_export(job, output_path)
          job
        end
      end

      private

      def extract_translation_memory_id(translation_memory)
        id = if translation_memory.is_a?(Resources::TranslationMemory)
               translation_memory.translation_memory_id
             else
               translation_memory
             end
        raise ArgumentError, 'Translation memory ID must not be empty' if blank?(id)

        id
      end

      def extract_job_id(job)
        id = job.is_a?(Resources::TranslationMemoryJob) ? job.job_id : job
        raise ArgumentError, 'Job ID must not be empty' if blank?(id)

        id
      end

      def extract_upload_url(translation_memory_import)
        if translation_memory_import.is_a?(Resources::TranslationMemoryImport)
          translation_memory_import.upload_url
        else
          translation_memory_import
        end
      end

      def extract_download_url(job)
        return job unless job.is_a?(Resources::TranslationMemoryJob)

        download_url = job.result&.download_url
        if blank?(download_url)
          raise Exceptions::Error, 'Translation memory export job has no download URL, ' \
                                   'it may not have completed yet'
        end

        download_url
      end

      def blank?(value)
        value.nil? || value.empty?
      end

      # The job of a creation response, before its first status query.
      def created_job(job_id, operation)
        Resources::TranslationMemoryJob.new(
          { 'job_id' => job_id, 'product' => 'translation_memory', 'operation' => operation },
          nil, nil
        )
      end

      def upload_and_wait(created, file_content, content_type, timeout_s, progress)
        progress[:job] = created_job(created.job_id, Resources::TranslationMemoryJob::OPERATION_IMPORT)
        upload_file(created, file_content, content_type: content_type)
        wait_until_job_done(created.job_id, timeout_s: timeout_s) { progress[:job] = _1 }
      end

      # Wraps every failure of the block in a TranslationMemoryJobError carrying +progress[:job]+,
      # the job once the block created it.
      def with_job_error(operation)
        progress = {}
        yield progress
      rescue StandardError => e
        prefix = "Error occurred during the translation memory #{operation}"
        # A failed job's error from the wait already starts with the prefix.
        message = e.message.start_with?(prefix) ? e.message : "#{prefix}: #{e.message}"
        raise Exceptions::TranslationMemoryJobError.new(message, progress[:job], e)
      end

      def check_input_file(input_file_path)
        return if File.exist?(input_file_path)

        raise ArgumentError, "No file found at #{input_file_path}"
      end

      def read_input_file(input_file_path)
        File.binread(input_file_path)
      rescue SystemCallError, IOError => e
        raise Exceptions::Error, "Could not read #{input_file_path}: #{e.message}"
      end

      def check_output_path(output_path)
        directory = File.dirname(output_path)
        unless File.directory?(directory)
          raise Exceptions::Error, "Output directory #{directory} does not exist"
        end
        unless File.writable?(directory)
          raise Exceptions::Error, "Output directory #{directory} is not writable"
        end
        raise Exceptions::Error, "File already exists at #{output_path}" if File.exist?(output_path)
      end

      def log_job_polling(interval)
        @api.configuration.logger&.info('Rechecking translation memory job status after sleeping ' \
                                        "for #{format('%.2f', interval)} seconds.")
      end

      def monotonic_time
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      # The polling interval, cut to the time left until +deadline+ so that a wait never runs
      # past +timeout_s+.
      def polling_interval_until(deadline, timeout_s)
        return JOB_POLLING_INTERVAL_SECONDS if deadline.nil?

        remaining = deadline - monotonic_time
        raise_timeout_error(timeout_s) if remaining <= 0

        [JOB_POLLING_INTERVAL_SECONDS, remaining].min
      end

      def raise_timeout_error(timeout_s)
        raise Exceptions::Error,
              "Manual timeout of #{timeout_s}s exceeded for the translation memory job"
      end

      def raise_job_error(job_status)
        raise Exceptions::Error,
              "Error occurred during the translation memory #{job_status.operation}: " \
              "#{job_status.error_message || job_status.status}"
      end
    end
  end
end
