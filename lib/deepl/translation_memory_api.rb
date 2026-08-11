# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  class TranslationMemoryApi # rubocop:disable Metrics/ClassLength
    # Time to wait between two status queries of an import or export job.
    JOB_POLLING_INTERVAL_SECONDS = 5

    def initialize(api, options = {})
      @api = api
      @options = options
    end

    ##
    # Lists the translation memories of the account.
    #
    # @param [Hash] options Additional options for the request. Supports `page` (page number for
    #                       pagination, 0-indexed) and `page_size` (number of items per page).
    # @return [Array<DeepL::Resources::TranslationMemory>] The translation memories of the page.

    def list(options = {})
      DeepL::Requests::TranslationMemory::List.new(@api, options).request
    end

    ##
    # Retrieves a single translation memory.
    #
    # @param [String, DeepL::Resources::TranslationMemory] translation_memory Translation memory
    #                                                                         ID or object.
    # @param [Hash] options Additional options for the request.
    # @return [DeepL::Resources::TranslationMemory] The requested translation memory.

    def find(translation_memory, options = {})
      DeepL::Requests::TranslationMemory::Find.new(
        @api, extract_translation_memory_id(translation_memory), options
      ).request
    end

    ##
    # Retrieves one page of the segments of a translation memory. Pagination is cursor-based:
    # omit `page_cursor` on the first call, then pass the `next_page_cursor` of the previous
    # response until it is nil.
    #
    # @param [String, DeepL::Resources::TranslationMemory] translation_memory Translation memory
    #                                                                         ID or object.
    # @param [Hash] options Additional options for the request. Supports `page_size` (maximum
    #                       number of segments per page, 1-100, defaults to 50), `page_cursor`
    #                       (cursor of a previous response), `filter_text` (substring filter
    #                       across source and target text, at least 2 characters) and
    #                       `filter_case_sensitive` (whether the filter is case-sensitive,
    #                       defaults to false).
    # @return [DeepL::Resources::TranslationMemorySegments] The requested page of segments.

    def segments(translation_memory, options = {})
      DeepL::Requests::TranslationMemory::Segments.new(
        @api, extract_translation_memory_id(translation_memory), options
      ).request
    end

    ##
    # Deletes a translation memory.
    #
    # @param [String, DeepL::Resources::TranslationMemory] translation_memory Translation memory
    #                                                                         ID or object.
    # @param [Hash] options Additional options for the request.
    # @return [String] The ID of the deleted translation memory.

    def destroy(translation_memory, options = {})
      DeepL::Requests::TranslationMemory::Destroy.new(
        @api, extract_translation_memory_id(translation_memory), options
      ).request
    end

    ##
    # Creates an import job for a new translation memory. The job only declares the file, upload
    # the TMX file itself to the returned upload URL with `upload_file`, then poll `find_job` for
    # the outcome. Use `import_from_filepath` to do all three steps at once.
    #
    # @param [String] file_name Name of the TMX file to import, for example "legal.tmx".
    # @param [Integer] content_length Size of the TMX file in bytes.
    # @param [String, nil] content_type MIME type of the file, defaults to "application/xml".
    # @param [String, nil] display_name Name of the resulting translation memory, defaults to the
    #                                   file name.
    # @param [Hash] additional_headers Additional HTTP headers for the request.
    # @return [DeepL::Resources::TranslationMemoryImport] The job ID and the upload URL.

    def create_import(file_name, content_length, content_type: nil, display_name: nil,
                      additional_headers: {})
      DeepL::Requests::TranslationMemory::CreateImport.new(
        @api, file_name, content_length,
        { content_type: content_type, display_name: display_name }.compact, additional_headers
      ).request
    end

    ##
    # Uploads a TMX file to the upload URL of an import job, which starts the processing. The
    # upload URL is a pre-signed storage URL outside of the DeepL API, so no authorization header
    # is sent with this request.
    #
    # @param [String, DeepL::Resources::TranslationMemoryImport] translation_memory_import Import
    #        returned by `create_import`, or its upload URL.
    # @param [String] file_content Content of the TMX file.
    # @param [String] content_type MIME type of the file. Must match the `content_type` declared
    #                              when the import job was created.
    # @return [nil]

    def upload_file(translation_memory_import, file_content,
                    content_type: Requests::TranslationMemory::UploadFile::DEFAULT_CONTENT_TYPE)
      DeepL::Requests::TranslationMemory::UploadFile.new(
        @api, extract_upload_url(translation_memory_import), file_content, content_type
      ).request
    end

    ##
    # Creates an export job for a translation memory. Poll `find_job` for the download URL of the
    # exported TMX file. Use `export_to_filepath` to do both steps and write the file at once.
    #
    # @param [String, DeepL::Resources::TranslationMemory] translation_memory Translation memory
    #                                                                         ID or object.
    # @param [Hash] options Additional options for the request.
    # @return [DeepL::Resources::TranslationMemoryExport] The job ID, and whether the API reused a
    #                                                     previously completed export.

    def create_export(translation_memory, options = {})
      DeepL::Requests::TranslationMemory::CreateExport.new(
        @api, extract_translation_memory_id(translation_memory), options
      ).request
    end

    ##
    # Retrieves the status of a translation memory import or export job.
    #
    # @param [String, DeepL::Resources::TranslationMemoryJob] job Job ID or object.
    # @param [Hash] options Additional options for the request.
    # @return [DeepL::Resources::TranslationMemoryJob] The current status of the job.

    def find_job(job, options = {})
      DeepL::Requests::TranslationMemory::FindJob.new(@api, extract_job_id(job), options).request
    end

    ##
    # Polls a translation memory import or export job until it is finished, `sleep`ing between
    # the status queries, and returns the final status.
    #
    # Note that an import job keeps reporting `awaiting_input` for a while after its file has
    # been uploaded, because the API detects the upload asynchronously. That status is therefore
    # polled through like any other non-terminal one. A job whose file is never uploaded does not
    # finish on its own, so pass `timeout_s` when that is a possibility.
    #
    # @raise [DeepL::Exceptions::Error] If the job failed or expired, or if `timeout_s` elapsed
    #                                   before the job finished.
    #
    # @param [String, DeepL::Resources::TranslationMemoryJob] job Job ID or object.
    # @param [Hash] options Additional options for the status queries.
    # @param [Numeric, nil] timeout_s Maximum time in seconds to wait for the job to finish. Note
    #                                 that this is not accurate to the second, the status is only
    #                                 queried every five seconds.
    # @return [DeepL::Resources::TranslationMemoryJob] The finished job.

    def wait_until_job_done(job, options = {}, timeout_s: nil)
      job_status = find_job(job, options)
      started_at = monotonic_time
      until job_status.finished?
        raise_timeout_error(timeout_s) if timeout_exceeded?(started_at, timeout_s)

        log_job_polling
        sleep(JOB_POLLING_INTERVAL_SECONDS)
        job_status = find_job(job, options)
      end
      raise_job_error(job_status) if job_status.error?

      job_status
    end

    ##
    # Downloads the TMX file of a completed export job. The download URL is a pre-signed storage
    # URL outside of the DeepL API, so no authorization header is sent with this request.
    #
    # @raise [DeepL::Exceptions::Error] If the job carries no download URL, for example because
    #                                   it has not completed yet.
    #
    # @param [DeepL::Resources::TranslationMemoryJob, String] job Completed export job carrying
    #        the download URL, or the download URL itself.
    # @param [String] output_path Path to the file to write to. Will be overwritten if the file
    #                             already exists.

    def download_export(job, output_path)
      DeepL::Requests::TranslationMemory::DownloadExport.new(@api, extract_download_url(job),
                                                             output_path).request
    end

    ##
    # Imports a TMX file as a new translation memory: creates the import job, uploads the file
    # and waits for the processing to finish.
    #
    # @raise [DeepL::Exceptions::Error] If the import fails.
    #
    # @param [String] input_file_path Path to the TMX file to import.
    # @param [String, nil] display_name Name of the resulting translation memory, defaults to the
    #                                   file name.
    # @param [Numeric, nil] timeout_s Maximum time in seconds to wait for the import to finish.
    #                                 Note that the API keeps reporting `awaiting_input` for a
    #                                 while after the upload, so allow for a generous timeout.
    # @return [DeepL::Resources::TranslationMemoryJob] The finished import job, its result carries
    #                                                  the ID of the new translation memory.

    def import_from_filepath(input_file_path, display_name: nil, timeout_s: nil)
      unless File.exist?(input_file_path)
        raise Exceptions::Error, "No file found at #{input_file_path}"
      end

      file_content = File.binread(input_file_path)
      created = create_import(File.basename(input_file_path), file_content.bytesize,
                              display_name: display_name)
      upload_file(created, file_content)
      wait_until_job_done(created.job_id, timeout_s: timeout_s)
    end

    ##
    # Exports a translation memory to a TMX file: creates the export job, waits for it to finish
    # and writes the result to +output_path+.
    #
    # @raise [DeepL::Exceptions::Error] If the export fails.
    #
    # @param [String, DeepL::Resources::TranslationMemory] translation_memory Translation memory
    #                                                                         ID or object.
    # @param [String] output_path Path to the file to write to. Will be overwritten if the file
    #                             already exists.
    # @param [Numeric, nil] timeout_s Maximum time in seconds to wait for the export to finish.
    # @return [DeepL::Resources::TranslationMemoryJob] The finished export job.

    def export_to_filepath(translation_memory, output_path, timeout_s: nil)
      created = create_export(translation_memory)
      job = wait_until_job_done(created.job_id, timeout_s: timeout_s)
      download_export(job, output_path)
      job
    end

    private

    def extract_translation_memory_id(translation_memory)
      id = if translation_memory.is_a?(Resources::TranslationMemory)
             translation_memory.translation_memory_id
           else
             translation_memory
           end
      raise Exceptions::Error, 'Translation memory ID must not be empty' if blank?(id)

      id
    end

    def extract_job_id(job)
      id = job.is_a?(Resources::TranslationMemoryJob) ? job.job_id : job
      raise Exceptions::Error, 'Job ID must not be empty' if blank?(id)

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

    def log_job_polling
      @api.configuration.logger&.info('Rechecking translation memory job status after sleeping ' \
                                      "for #{JOB_POLLING_INTERVAL_SECONDS} seconds.")
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def timeout_exceeded?(started_at, timeout_s)
      !timeout_s.nil? && (monotonic_time - started_at) > timeout_s
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
