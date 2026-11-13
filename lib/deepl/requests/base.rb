# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    class Base # rubocop:disable Metrics/ClassLength
      # Maximum number of glossaries that may be provided via the +glossary_ids+ option.
      MAX_GLOSSARY_IDS = 5

      # Transient network failures, which are retried: DNS (SocketError), timeouts
      # (Net::OpenTimeout and Net::ReadTimeout are Timeout::Errors), refused or reset connections,
      # broken pipes and unreachable hosts (SystemCallError), and connections closed early.
      RETRYABLE_NETWORK_ERRORS = [Timeout::Error, SocketError, SystemCallError, EOFError].freeze

      # Network failures without an HTTP response from the API. TLS failures, malformed responses
      # and proxy failures (Net::ProtocolError, raised when a proxy refuses CONNECT, e.g. with 407)
      # are not transient and are raised without retrying.
      NETWORK_ERRORS = [*RETRYABLE_NETWORK_ERRORS, Net::HTTPBadResponse,
                        OpenSSL::SSL::SSLError, Net::ProtocolError].freeze

      # Errors raised while building the result from a received response: the response has an
      # unexpected format.
      RESPONSE_FORMAT_ERRORS = [JSON::ParserError, NoMethodError, TypeError, KeyError].freeze

      # Headers that describe the request the SDK builds; a caller's value is dropped.
      TECHNICAL_HEADERS = %w[content-type content-length transfer-encoding host].freeze

      # A POST without a body. REQUEST_HAS_BODY false keeps Net::HTTP from sending '' with a
      # default form Content-Type (net-http before 0.7).
      class BodilessPost < Net::HTTPRequest
        METHOD = 'POST'
        REQUEST_HAS_BODY = false
        RESPONSE_HAS_BODY = true
      end

      # Wraps +request+ of every request class, so that a malformed response raises a
      # DeepL::Exceptions::Error instead of a raw JSON or type error.
      module ResponseFormatGuard
        def request
          super
        rescue *RESPONSE_FORMAT_ERRORS => e
          raise e unless @response_received

          raise Exceptions::Error, "Unexpected response from the DeepL API: #{e.message}"
        end
      end

      def self.inherited(subclass)
        super
        subclass.prepend(ResponseFormatGuard)
      end

      # Declares the options a request class accepts besides +extra_body_parameters+. Any other
      # option raises ArgumentError before a request is sent.
      def self.accepts_options(*names)
        @accepted_options = names.map(&:to_s).freeze
      end

      def self.accepted_options
        @accepted_options || []
      end

      # @raise [ArgumentError] If +options+ has an option the class does not accept.
      def self.validate_options!(options)
        accepted = accepted_options + ['extra_body_parameters']
        unknown = options.keys.reject { |name| accepted.include?(name.to_s) }
        return if unknown.empty?

        names = unknown.map { |name| "`#{name}`" }.join(', ')
        raise ArgumentError, "Unknown option#{'s' if unknown.size > 1} #{names}; use " \
                             '`extra_body_parameters` to send fields the SDK does not model'
      end

      attr_reader :api, :response, :options

      # Options set to nil are unset and not sent.
      def initialize(api, options = {}, additional_headers = {})
        @api = api
        self.class.validate_options!(options)
        @options = options.compact
        @additional_headers = additional_headers
        @num_retries = 0
        @backoff_timer = Utils::BackoffTimer.new
      end

      def request
        raise NotImplementedError
      end

      def details
        "HTTP Headers #{loggable_headers}"
      end

      private

      def option?(name)
        options.key?(name.to_s) || options.key?(name.to_sym)
      end

      def option(name)
        return options[name.to_s] if options.key?(name.to_s)

        options[name.to_sym]
      end

      def delete_option(name)
        return options.delete(name.to_s) if options.key?(name.to_s)

        options.delete(name.to_sym)
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
          payload[key.to_s] = value
        end
      end

      # Apply extra body parameters to multipart form data array
      # Extra parameters will override existing keys; a nil value removes the key.
      def apply_extra_body_parameters_to_form(form_data)
        return unless option?(:extra_body_parameters)

        extra_params = option(:extra_body_parameters)
        extra_params.each do |key, value|
          key_str = key.to_s
          # Remove existing key if present to allow override.
          # Required for form data as it would be duplicated otherwise
          form_data.reject! { |field| field[0].to_s == key_str }
          form_data.push([key_str, value.to_s]) unless value.nil?
        end
      end

      # Files to reset: list of file objects to rewind when retrying the request
      def execute_request_with_retries(req, files_to_reset = []) # rubocop:disable all
        api.configuration.logger&.info("Request to the DeepL API: #{self}")
        api.configuration.logger&.debug("Request details: #{details}")
        loop do
          resp = nil
          response_started = false
          client = http_client
          apply_request_timeout(client)
          connected = client.started?
          exchange = lambda do |http|
            connected = true
            http.request(req) do |response|
              response_started = true
              read_complete_body(response)
            end
          end
          resp = connected ? exchange.call(client) : client.start(&exchange)
          validate_response!(resp, req)
          @response_received = true
          return [req, resp]
        rescue DeepL::Exceptions::Error => e
          raise e unless should_retry?(resp, e, @backoff_timer.num_retries)

          wait_before_retry(e, files_to_reset)
          next
        rescue *NETWORK_ERRORS => e
          retry_error = retry_network_error?(e, connected)
          raise_network_error(e, response_started, connected) unless retry_error

          wait_before_retry(e, files_to_reset)
          next
        end
      end

      # A create does not retry an EOFError; it has +should_retry?+ true only once the response
      # headers arrived (a body cut off mid-read), false for a connection closed before the
      # response.
      def raise_network_error(error, response_started, connected)
        should_retry = !retry_only_unprocessed? || !connected ||
                       (response_started && error.is_a?(EOFError))
        raise Exceptions::ConnectionError.from_network_error(error, should_retry: should_retry)
      end

      # Before net-http 0.3, Net::HTTP cannot raise at EOF of a short body (+ignore_eof+), so the
      # body is compared with Content-Length. An inflated body has no comparable length.
      def read_complete_body(response)
        encoding = response['content-encoding']
        expected = response.content_length unless response.chunked?
        body = response.read_body
        return if body.nil? || expected.nil? || !(encoding.nil? || encoding == 'identity')
        return if body.bytesize >= expected

        raise EOFError, "Response body ended after #{body.bytesize} of #{expected} bytes"
      end

      # Per attempt, the timeout is the configured timeout or, if longer, the time until the
      # backoff deadline. Timeouts given in HTTPClientOptions take precedence.
      def apply_request_timeout(client) # rubocop:disable Metrics/AbcSize
        timeout = api.configuration.timeout
        return if timeout.nil? || !client.respond_to?(:read_timeout=)

        timeout = [timeout.to_f, @backoff_timer.time_until_deadline].max
        options = http_client_options_of(client)
        client.open_timeout = timeout if options&.open_timeout.nil?
        client.read_timeout = timeout if options&.read_timeout.nil?
        client.write_timeout = timeout if options&.write_timeout.nil?
      end

      # The HTTPClientOptions +client+ was built with, if any.
      def http_client_options_of(client)
        client.equal?(api.http_client) ? api.http_client_options : nil
      end

      def wait_before_retry(error, files_to_reset)
        logger = api.configuration.logger
        logger&.info("Encountered a retryable exception: #{error.message}")
        logger&.info("Starting retry #{@backoff_timer.num_retries + 1} for " \
                     "request #{self} after sleeping for " \
                     "#{format('%.2f', @backoff_timer.time_until_deadline)}")
        files_to_reset.each(&:rewind)
        @backoff_timer.sleep_until_deadline
      end

      def retry_network_error?(error, connected)
        Exceptions::ConnectionError.transient?(error) &&
          @backoff_timer.num_retries < api.configuration.max_network_retries &&
          (!retry_only_unprocessed? || !connected)
      end

      def should_retry?(response, exception, num_retries)
        return false if num_retries >= api.configuration.max_network_retries
        return exception.should_retry? if response.nil?

        return response.is_a?(Net::HTTPTooManyRequests) if retry_only_unprocessed?

        response.is_a?(Net::HTTPTooManyRequests) || (500..599).cover?(response.code.to_i)
      end

      # Requests that are unsafe to repeat return true to retry only failures that show the
      # request was not processed: HTTP 429, and every transient network failure raised before
      # the connection is up (TCP connect, proxy CONNECT, TLS handshake), when no request byte was
      # written.
      def retry_only_unprocessed?
        false
      end

      # The request body: the SDK's payload, then the remaining declared options, then
      # +extra_body_parameters+, which replace an SDK field of the same name.
      def json_body(payload)
        body = payload.merge(options_without_extra_params).transform_keys(&:to_s)
        apply_extra_body_parameters_to_json(body)
        body.to_json
      end

      def post_request(payload)
        http_headers = add_json_content_type(headers)
        post_req = Net::HTTP::Post.new(uri.path, http_headers)
        post_req.body = json_body(payload)
        post_req
      end

      def post_request_with_file(form_data)
        http_headers = add_multipart_form_content_type(headers)
        post_req = Net::HTTP::Post.new(uri.request_uri, http_headers)
        post_req.set_form(form_data, 'multipart/form-data')
        post_req
      end

      # GET and DELETE send no body, so no Content-Type either.
      def get_request # rubocop:disable Naming/AccessorMethodName
        Net::HTTP::Get.new(uri.path, headers)
      end

      def bodiless_post_request
        BodilessPost.new(uri.path, headers.merge('Content-Length' => '0'))
      end

      def patch_request(payload)
        http_headers = add_json_content_type(headers)
        req = Net::HTTP::Patch.new(uri.path, http_headers)
        req.body = json_body(payload)
        req
      end

      def put_request(payload)
        http_headers = add_json_content_type(headers)
        req = Net::HTTP::Put.new(uri.path, http_headers)
        req.body = json_body(payload)
        req
      end

      def delete_request
        Net::HTTP::Delete.new(uri.path, headers)
      end

      def validate_response!(response, request = nil)
        return if response.is_a?(Net::HTTPSuccess)
        # A request that is unsafe to repeat may have been processed before the server failed.
        if retry_only_unprocessed? && (500..599).cover?(response.code.to_i)
          raise Exceptions::ServerError.new(response, request, should_retry: false)
        end

        raise Utils::ExceptionBuilder.new(response, request).build
      end

      # Validates the +glossary_ids+ option and resolves it to an array of glossary ID strings.
      #
      # The +glossary_ids+ option accepts an array of up to `MAX_GLOSSARY_IDS` glossary
      # identifiers. Each entry may be a glossary ID string, a
      # `DeepL::Resources::Glossary` or a `DeepL::Resources::MultilingualGlossary` object. It:
      # * cannot be combined with the singular +glossary+ option,
      # * allows at most `MAX_GLOSSARY_IDS` identifiers.
      #
      # The API expects +glossary_ids+ as an array (a JSON array in the JSON translate body).
      # Callers sending multipart/form-data (e.g. document upload) should join the returned
      # array into a comma-separated string.
      #
      # @return [Array<String>, nil] The list of glossary IDs, or nil if the +glossary_ids+
      #                              option was not provided.
      # @raise [ArgumentError] If any of the validation rules above are violated.
      def build_glossary_ids_param
        return nil unless option?(:glossary_ids)

        ids = Array(delete_option(:glossary_ids))
        return nil if ids.empty?

        validate_glossary_ids!(ids)
        ids.map { |glossary| glossary_id_string('An entry of `glossary_ids`', glossary) }
      end

      # Resolves the +glossary+ option (a glossary ID string, a `DeepL::Resources::Glossary` or
      # a `DeepL::Resources::MultilingualGlossary`) to the ID sent as +glossary_id+.
      #
      # @return [String, nil] The glossary ID, or nil if the +glossary+ option is unset.
      def build_glossary_param
        return nil unless option?(:glossary)

        glossary = delete_option(:glossary)
        return nil if glossary.nil?

        glossary_id_string('`glossary`', glossary)
      end

      def glossary_id_string(name, glossary)
        resource_id!(name, glossary,
                     [DeepL::Resources::Glossary, DeepL::Resources::MultilingualGlossary], :id)
      end

      # Removes the resource option +name+ and returns its ID, nil if the option is unset or nil.
      def take_resource_option(name, types, id_method)
        value = delete_option(name)
        resource_id!("`#{name}`", value, types, id_method) unless value.nil?
      end

      # Resolves +value+, an ID or a resource object of one of +types+, to the ID.
      #
      # @raise [ArgumentError] If the ID is nil or empty.
      def resource_id!(name, value, types, id_method)
        id = types.any? { |type| value.is_a?(type) } ? value.public_send(id_method) : value
        return id.to_s unless id.to_s.empty?

        raise ArgumentError, "#{name} must be a non-empty ID or a resource object with its ID"
      end

      def validate_glossary_ids!(ids)
        validate_no_single_glossary!
        return unless ids.size > MAX_GLOSSARY_IDS

        raise ArgumentError,
              "A maximum of #{MAX_GLOSSARY_IDS} glossary IDs may be provided via `glossary_ids`"
      end

      def validate_no_single_glossary!
        return if option(:glossary).nil?

        raise ArgumentError,
              'The `glossary_ids` option cannot be used together with the `glossary` option'
      end

      # @raise [ArgumentError] Unless +text+ is a non-empty string or a non-empty array of
      #   non-empty strings.
      def validate_text!(text)
        texts = text.is_a?(Array) ? text : [text]
        return unless texts.empty? || texts.any? { |t| t.to_s.empty? }

        raise ArgumentError,
              '`text` must be a non-empty string or a non-empty array of non-empty strings'
      end

      # @raise [ArgumentError] If +target_lang+ is empty or +source_lang+ is given but empty.
      def validate_languages!(source_lang, target_lang)
        raise ArgumentError, '`target_lang` must not be empty' if target_lang.to_s.empty?
        return unless !source_lang.nil? && source_lang.to_s.empty?

        raise ArgumentError, '`source_lang` must not be empty; pass nil to detect it'
      end

      # @raise [ArgumentError] If the language is empty, or nil unless +optional+. An optional
      #   language that is nil is not sent.
      def validate_language!(name, language, optional: false)
        return unless language.to_s.empty?
        return if optional && language.nil?

        raise ArgumentError,
              "`#{name}` must not be empty#{'; pass nil to leave it unset' if optional}"
      end

      # @raise [ArgumentError] If the +translation_memory_threshold+ option is set without the
      #   +translation_memory+ option or is not an Integer from 0 to 100.
      def validate_translation_memory_threshold!
        threshold = option(:translation_memory_threshold)
        return if threshold.nil?

        unless option?(:translation_memory)
          raise ArgumentError, '`translation_memory_threshold` requires `translation_memory`'
        end
        return if threshold.is_a?(Integer) && threshold.between?(0, 100)

        raise ArgumentError, '`translation_memory_threshold` must be an Integer from 0 to 100'
      end

      def path
        raise NotImplementedError
      end

      # URL-encodes a value for use as one path segment (a space as %20, not +).
      def escape_path_segment(value)
        URI.encode_www_form_component(value.to_s).gsub('+', '%20')
      end

      # URL-encodes +params+ as a query string per RFC 3986. encode_www_form writes a space as +,
      # which is right for a form body only; a literal + is already %2B, so every + is a space.
      def encode_query(params)
        URI.encode_www_form(params).gsub('+', '%20')
      end

      def url
        "#{host}/v2/#{path}"
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

      # The configured +headers+, then the per-call additional headers, each replace a header of
      # the same name in any casing, Authorization and User-Agent included.
      def headers
        library = { 'Authorization' => "DeepL-Auth-Key #{api.configuration.auth_key.to_s.strip}",
                    'User-Agent' => api.configuration.user_agent }
        merge_headers(library, api.configuration.headers, @additional_headers)
      end

      def merge_headers(base, *given_headers)
        given_headers.each_with_object(base) do |given, merged|
          (given || {}).each do |name, value|
            next if TECHNICAL_HEADERS.include?(name.to_s.downcase)

            merged.delete_if { |existing, _| existing.to_s.casecmp?(name.to_s) }
            merged[name] = value
          end
        end
      end

      def loggable_headers
        headers.to_h do |name, value|
          name.to_s.casecmp?('authorization') ? [name, 'DeepL-Auth-Key [REDACTED]'] : [name, value]
        end
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
