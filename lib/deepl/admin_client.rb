# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  ##
  # Client for the DeepL Admin API, used to manage the developer keys of your organization and
  # to retrieve usage analytics. It is independent of +DeepL.configure+ and never reads the
  # +DEEPL_AUTH_KEY+ or +DEEPL_SERVER_URL+ environment variables.
  #
  # All methods may raise a +DeepL::Exceptions::Error+ or a subclass, for example
  # +DeepL::Exceptions::AuthorizationFailed+ if the admin key is not accepted.
  class AdminClient
    DEEPL_SERVER_URL = 'https://api.deepl.com'
    private_constant :DEEPL_SERVER_URL

    ##
    # @param [String] admin_key Admin API key, surrounding whitespace is removed.
    # @param [String, nil] server_url Base URL of the DeepL API, defaults to
    #   +https://api.deepl.com+ (also for keys ending in +:fx+).
    # @param [Hash] headers HTTP headers sent with every request. A +User-Agent+ replaces the
    #   library's; +Authorization+ cannot be replaced.
    # @param [Integer] max_retries Number of retries after the first attempt.
    # @param [Numeric] timeout Timeout of each attempt in seconds.
    # @param [String, nil] proxy Proxy URL, e.g. +http://user:password@proxy.example:8080+.
    # @param [Boolean] send_platform_info Whether to send basic platform information.
    # @param [DeepL::AppInfo, Hash, nil] app_info Your application's +app_name+ and
    #   +app_version+, added to the +User-Agent+.
    # @param [DeepL::HTTPClientOptions, nil] http_client_options Proxy, SSL and timeout options.
    # @param [Logger, nil] logger Logger for requests and retries.
    # @raise [ArgumentError] If +admin_key+ is empty.
    def initialize(admin_key, server_url: nil, headers: {}, max_retries: 5, timeout: 10, # rubocop:disable Metrics/ParameterLists
                   proxy: nil, send_platform_info: true, app_info: nil, http_client_options: nil,
                   logger: nil)
      @api = Utils::ClientBuilder.build_api(
        admin_key, key_name: 'admin_key', server_url: server_url,
                   default_server_url: DEEPL_SERVER_URL, headers: headers,
                   max_retries: max_retries, timeout: timeout, proxy: proxy,
                   send_platform_info: send_platform_info, app_info: app_info,
                   http_client_options: http_client_options, logger: logger
      )
    end

    def inspect
      "#<#{self.class.name} server_url=#{configuration.host}>"
    end

    ##
    # Retrieves the usage of the organization within a date range. The API requires the start date
    # to be before the end date (a report covers at least two days) and the range to be at most
    # 366 days.
    #
    # @param [Date, Time, DateTime, String] start_date Start date, as a +Date+, a +Time+, a
    #   +DateTime+ or a +YYYY-MM-DD+ string. Dates are UTC calendar days and both the start and
    #   the end day are included. For +Time+ and +DateTime+ values the UTC date of that moment is
    #   sent: +2026-10-20 00:00 +02:00+ is sent as +2026-10-19+.
    # @param [Date, Time, DateTime, String] end_date End date, in the same format as +start_date+.
    # @param [String, Symbol, nil] group_by Group the usage by key or by key and day, see
    #   +DeepL::Constants::AdminUsageGroupBy+ for the accepted values. It is sent as is, and the
    #   +group_by+ of the report is the raw string the API returns.
    # @return [DeepL::Resources::AdminUsageReport]
    # @raise [ArgumentError] If a date is invalid.
    # @raise [DeepL::Exceptions::BadRequest] If the API rejects the date range.
    def get_usage_analytics(start_date, end_date, group_by: nil)
      Requests::Admin::UsageAnalytics.new(api, start_date, end_date, group_by).request
    end

    ##
    # Retrieves the usage per custom tag within a date range, with the same limits as
    # +get_usage_analytics+. Results are paginated: pass the +next_page+ of a report as +page+ to
    # retrieve the following page.
    #
    # @param [Date, Time, DateTime, String] start_date Start date, as a +Date+, a +Time+, a
    #   +DateTime+ or a +YYYY-MM-DD+ string. Dates are UTC calendar days and both the start and
    #   the end day are included. For +Time+ and +DateTime+ values the UTC date of that moment is
    #   sent: +2026-10-20 00:00 +02:00+ is sent as +2026-10-19+.
    # @param [Date, Time, DateTime, String] end_date End date, in the same format as +start_date+.
    # @param [String, Symbol, nil] aggregate_by Aggregate the usage over the whole period or by
    #   day, see +DeepL::Constants::CustomTagUsageAggregateBy+. It is sent as is, and the
    #   +aggregate_by+ of the report is the raw string the API returns.
    # @param [Integer, nil] page Page number to retrieve.
    # @return [DeepL::Resources::CustomTagUsageReport]
    # @raise [ArgumentError] If a date is invalid.
    # @raise [DeepL::Exceptions::BadRequest] If the API rejects the date range.
    def get_custom_tag_usage_analytics(start_date, end_date, aggregate_by: nil, page: nil)
      Requests::Admin::CustomTagUsageAnalytics.new(api, start_date, end_date, aggregate_by,
                                                   page).request
    end

    ##
    # Creates a developer key. The API uses "DeepL API Key" as label if none is given.
    #
    # Creation is retried only after failures that show the request was not processed (HTTP 429,
    # DNS resolution errors and connection timeouts), so that a retry cannot create a second key.
    #
    # @param [String, nil] label Label for the new key, not sent if +nil+.
    # @param [Hash, nil] extra_body_parameters Added to the request body last; replaces fields
    #   of the same name. Values are sent as given.
    # @return [DeepL::Resources::DeveloperKey]
    def create_developer_key(label: nil, extra_body_parameters: nil)
      Requests::Admin::CreateDeveloperKey.new(api, label, extra_body_parameters).request
    end

    ##
    # Retrieves all developer keys of the organization, including deactivated ones.
    #
    # @return [Array<DeepL::Resources::DeveloperKey>]
    def list_developer_keys
      Requests::Admin::ListDeveloperKeys.new(api).request
    end

    ##
    # Deactivates a developer key. Deactivation is permanent.
    #
    # @param [String, DeepL::Resources::DeveloperKey] key Key ID or developer key.
    # @param [Hash, nil] extra_body_parameters Added to the request body last; replaces fields
    #   of the same name. Values are sent as given.
    # @return [DeepL::Resources::DeveloperKey]
    # @raise [ArgumentError] If the key ID is empty.
    def deactivate_developer_key(key, extra_body_parameters: nil)
      update_developer_key('deactivate', { key_id: key_id(key) }, extra_body_parameters)
    end

    ##
    # Changes the label of a developer key.
    #
    # @param [String, DeepL::Resources::DeveloperKey] key Key ID or developer key.
    # @param [String] label New label for the key.
    # @param [Hash, nil] extra_body_parameters Added to the request body last; replaces fields
    #   of the same name. Values are sent as given.
    # @return [DeepL::Resources::DeveloperKey]
    # @raise [ArgumentError] If the key ID is empty.
    def rename_developer_key(key, label, extra_body_parameters: nil)
      update_developer_key('label', { key_id: key_id(key), label: label }, extra_body_parameters)
    end

    ##
    # Changes the usage limits of a developer key. Only the given limits are changed; omitted
    # limits keep their current value. A +nil+ limit means unlimited and +0+ blocks that usage.
    #
    #   admin_client.set_developer_key_usage_limits(key, characters: 0)
    #   admin_client.set_developer_key_usage_limits(key, speech_to_text_milliseconds: nil)
    #
    # @param [String, DeepL::Resources::DeveloperKey] key Key ID or developer key.
    # @param [Hash] limits Limits to change: +:characters+ (characters per usage period across
    #   text translation, document translation and text improvement),
    #   +:speech_to_text_milliseconds+ and +:speech_to_speech_milliseconds+, each an +Integer+ or
    #   +nil+. They are sent as is and validated by the API.
    # @param [Hash, nil] extra_body_parameters Added to the request body last; replaces fields
    #   of the same name. Values are sent as given.
    # @return [DeepL::Resources::DeveloperKey]
    # @raise [ArgumentError] If the key ID is empty.
    def set_developer_key_usage_limits(key, extra_body_parameters: nil, **limits)
      update_developer_key('limits', limits.merge(key_id: key_id(key)), extra_body_parameters)
    end

    private

    attr_reader :api

    def configuration
      api.configuration
    end

    def update_developer_key(action, payload, extra_body_parameters)
      Requests::Admin::UpdateDeveloperKey.new(api, action, payload, extra_body_parameters).request
    end

    def key_id(key)
      id = key.is_a?(Resources::DeveloperKey) ? key.key_id : key
      raise ArgumentError, 'key ID must not be empty' if blank?(id)

      id
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end
