# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  class Configuration
    ATTRIBUTES = %i[auth_key host logger max_doc_status_queries max_network_retries user_agent
                    version headers timeout].freeze

    attr_accessor(*ATTRIBUTES)

    DEEPL_SERVER_URL = 'https://api.deepl.com'
    DEEPL_SERVER_URL_FREE = 'https://api-free.deepl.com'
    DEFAULT_TIMEOUT = 10.0
    private_constant :DEEPL_SERVER_URL, :DEEPL_SERVER_URL_FREE, :DEFAULT_TIMEOUT

    def initialize(data = {}, app_info_name = nil, app_info_version = nil, send_platform_info = true) # rubocop:disable all
      data.each { |key, value| send("#{key}=", value) }
      @auth_key ||= ENV.fetch('DEEPL_AUTH_KEY', nil)
      @host ||= ENV.fetch('DEEPL_SERVER_URL', nil)
      @version ||= 'v2'
      @user_agent ||= construct_user_agent(send_platform_info, app_info_name, app_info_version)
      @max_network_retries ||= 5
      @logger ||= nil
      @headers ||= {}
      @timeout ||= DEFAULT_TIMEOUT
    end

    # The host is resolved when it is read, so that an auth key set after the configuration was
    # created (e.g. in a +DeepL.configure+ block) still selects the Free API.
    def host
      return @host unless @host.nil?

      self.class.free_account_auth_key?(auth_key) ? DEEPL_SERVER_URL_FREE : DEEPL_SERVER_URL
    end

    ##
    # @deprecated The API version is part of each endpoint; this setting will be removed in the
    #   next major version.
    def version=(value)
      unless value.nil? || value == 'v2'
        DeepL::Deprecation.warn_once('DeepL::Configuration#version=',
                                     '[DEPRECATION] DeepL::Configuration#version= is deprecated ' \
                                     'and will be removed in the next major version.')
      end
      @version = value
    end

    def validate!
      return unless auth_key.nil? || auth_key.to_s.strip.empty?

      raise Exceptions::Error,
            'auth_key not provided'
    end

    def attributes
      ATTRIBUTES.to_h { |attr| [attr, send(attr)] }
    end

    def ==(other)
      attributes == other.attributes
    end

    def self.free_account_auth_key?(key)
      key&.end_with?(':fx')
    end

    def construct_user_agent(send_platform_info, app_info_name, app_info_version)
      library_info_str = "deepl-ruby/#{DeepL::VERSION}"
      if send_platform_info
        library_info_str += " (#{RbConfig::CONFIG['host_os']}) ruby/#{RUBY_VERSION}"
      end
      if app_info_name && app_info_version
        library_info_str += " #{app_info_name}/#{app_info_version}"
      end
      library_info_str
    end
  end
end
