# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    class Base # rubocop:disable Metrics/ClassLength
      # Maximum number of glossaries that may be provided via the +glossary_ids+ option.
      MAX_GLOSSARY_IDS = 5

      attr_reader :api, :response, :options

      def initialize(api, options = {}, additional_headers = {})
        @api = api
        @options = options
        @additional_headers = additional_headers
        @num_retries = 0
        @backoff_timer = Utils::BackoffTimer.new
      end

      def request
        raise NotImplementedError
      end

      def details
        "HTTP Headers #{headers}"
      end

      private

      def option?(name)
        options.key?(name.to_s) || options.key?(name.to_sym)
      end

      def option(name)
        options[name.to_s] || options[name.to_sym]
      end

      def delete_option(name)
        options.delete(name.to_s) || options.delete(name.to_sym)
      end

      def set_option(name, value)
        if options.key?(name.to_sym)
          options[name.to_sym] = value
        else
          options[name.to_s] = value
        end
      end

      # Returns options excluding extra_body_parameters
      # extra_body_parameters are applied separately via apply_extra_body_parameters_* methods
      def options_without_extra_params
        options.reject do |k, _|
          k.to_s == 'extra_body_parameters' || k.to_sym == :extra_body_parameters
        end
      end

      # Apply extra body parameters to a hash payload (for JSON/form-encoded requests)
      # Extra parameters will override existing keys
      def apply_extra_body_parameters_to_json(payload)
        return unless option?(:extra_body_parameters)

        extra_params = option(:extra_body_parameters)
        extra_params.each do |key, value|
          payload[key] = value
        end
      end

      # Apply extra body parameters to multipart form data array
      # Extra parameters will override existing keys
      def apply_extra_body_parameters_to_form(form_data)
        return unless option?(:extra_body_parameters)

        extra_params = option(:extra_body_parameters)
        extra_params.each do |key, value|
          key_str = key.to_s
          # Remove existing key if present to allow override.
          # Required for form data as it would be duplicated otherwise
          form_data.reject! { |field| field[0].to_s == key_str }
          form_data.push([key_str, value.to_s])
        end
      end

      # Files to reset: list of file objects to rewind when retrying the request
      def execute_request_with_retries(req, files_to_reset = []) # rubocop:disable all
        api.configuration.logger&.info("Request to the DeepL API: #{self}")
        api.configuration.logger&.debug("Request details: #{details}")
        loop do
          resp = http_client.request(req)
          validate_response!(resp)
          return [req, resp]
        rescue DeepL::Exceptions::Error => e
          raise e unless should_retry?(resp, e, @backoff_timer.num_retries)

          unless e.nil?
            api.configuration.logger&.info("Encountered a retryable exception: #{e.message}")
          end
          api.configuration.logger&.info("Starting retry #{@backoff_timer.num_retries + 1} for " \
                                         "request #{self} after sleeping for " \
                                         "#{format('%.2f', @backoff_timer.time_until_deadline)}")
          files_to_reset.each(&:rewind)
          @backoff_timer.sleep_until_deadline
          next
        rescue Net::HTTPBadResponse, Net::HTTPServerError, Net::HTTPFatalError, Timeout::Error,
               SocketError => e
          unless e.nil?
            api.configuration.logger&.info("Encountered a retryable exception: #{e.message}")
          end
          api.configuration.logger&.info("Starting retry #{@backoff_timer.num_retries + 1} for " \
                                         "request #{self} after sleeping for " \
                                         "#{format('%.2f', @backoff_timer.time_until_deadline)}")
          files_to_reset.each(&:rewind)
          @backoff_timer.sleep_until_deadline
          next
        end
      end

      def should_retry?(response, exception, num_retries)
        return false if num_retries >= api.configuration.max_network_retries
        return exception.should_retry? if response.nil?

        response.is_a?(Net::HTTPTooManyRequests) || response.is_a?(Net::HTTPInternalServerError)
      end

      def post_request(payload)
        apply_extra_body_parameters_to_json(payload)
        http_headers = add_json_content_type(headers)
        post_req = Net::HTTP::Post.new(uri.path, http_headers)
        post_req.body = payload.merge(options_without_extra_params).to_json
        post_req
      end

      def post_request_with_file(form_data)
        http_headers = add_multipart_form_content_type(headers)
        post_req = Net::HTTP::Post.new(uri.request_uri, http_headers)
        post_req.set_form(form_data, 'multipart/form-data')
        post_req
      end

      def get_request # rubocop:disable Naming/AccessorMethodName
        http_headers = add_json_content_type(headers)
        get_req = Net::HTTP::Get.new(uri.path, http_headers)
        get_req.body = options_without_extra_params.to_json
        get_req
      end

      def patch_request(payload)
        apply_extra_body_parameters_to_json(payload)
        http_headers = add_json_content_type(headers)
        req = Net::HTTP::Patch.new(uri.path, http_headers)
        req.body = payload.merge(options_without_extra_params).to_json
        req
      end

      def put_request(payload)
        apply_extra_body_parameters_to_json(payload)
        http_headers = add_json_content_type(headers)
        req = Net::HTTP::Put.new(uri.path, http_headers)
        req.body = payload.merge(options_without_extra_params).to_json
        req
      end

      def delete_request
        http_headers = add_json_content_type(headers)
        del_req = Net::HTTP::Delete.new(uri.path, http_headers)
        del_req.body = options_without_extra_params.to_json
        del_req
      end

      def validate_response!(response)
        return if response.is_a?(Net::HTTPSuccess)

        raise Utils::ExceptionBuilder.new(response).build
      end

      # Validates the +glossary_ids+ option and resolves it to an array of glossary ID strings.
      #
      # The +glossary_ids+ option accepts an array of up to `MAX_GLOSSARY_IDS` glossary
      # identifiers. Each entry may be a glossary ID string or a
      # `DeepL::Resources::Glossary` object. It:
      # * requires +source_lang+ to be set,
      # * cannot be combined with the singular +glossary_id+ option,
      # * allows at most `MAX_GLOSSARY_IDS` identifiers.
      #
      # The API expects +glossary_ids+ as an array (a JSON array in the JSON translate body).
      # Callers sending multipart/form-data (e.g. document upload) should join the returned
      # array into a comma-separated string.
      #
      # @param [String, nil] source_lang The source language for the request.
      # @return [Array<String>, nil] The list of glossary IDs, or nil if the +glossary_ids+
      #                              option was not provided.
      # @raise [ArgumentError] If any of the validation rules above are violated.
      def build_glossary_ids_param(source_lang)
        return nil unless option?(:glossary_ids)

        ids = Array(delete_option(:glossary_ids))
        return nil if ids.empty?

        validate_glossary_ids!(ids, source_lang)
        ids.map do |glossary|
          glossary.is_a?(DeepL::Resources::Glossary) ? glossary.id : glossary.to_s
        end
      end

      def validate_glossary_ids!(ids, source_lang)
        if option?(:glossary_id)
          raise ArgumentError,
                'The `glossary_ids` option cannot be used together with the `glossary_id` option'
        end
        if source_lang.nil?
          raise ArgumentError, 'The `glossary_ids` option requires `source_lang` to be set'
        end
        return unless ids.size > MAX_GLOSSARY_IDS

        raise ArgumentError,
              "A maximum of #{MAX_GLOSSARY_IDS} glossary IDs may be provided via `glossary_ids`"
      end

      def path
        raise NotImplementedError
      end

      def url
        "#{host}/#{api.configuration.version}/#{path}"
      end

      def uri
        @uri ||= URI(url)
        @uri
      end

      def host
        api.configuration.host
      end

      # Subclasses that talk to a host other than the DeepL API, such as a pre-signed storage
      # URL, override this to request through their own connection.
      def http_client
        api.http_client
      end

      def query_params
        options
      end

      def headers
        { 'Authorization' => "DeepL-Auth-Key #{api.configuration.auth_key}",
          'User-Agent' => api.configuration.user_agent }.merge(@additional_headers)
      end

      def add_json_content_type(headers_to_add_to)
        headers_to_add_to['Content-Type'] = 'application/json'
        headers_to_add_to
      end

      def add_multipart_form_content_type(headers_to_add_to)
        headers_to_add_to['Content-Type'] = 'multipart/form-data'
        headers_to_add_to
      end
    end
  end
end
