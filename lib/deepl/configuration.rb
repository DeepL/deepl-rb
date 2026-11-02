# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  # The options of one DeepL::Client or DeepL::AdminClient, built by Utils::ClientBuilder.
  # Nothing is read from the environment.
  # @api private
  class Configuration
    ATTRIBUTES = %i[auth_key host logger max_network_retries user_agent headers timeout].freeze

    attr_reader(*ATTRIBUTES)

    def initialize(auth_key:, host:, max_network_retries:, timeout:, logger:, headers:, # rubocop:disable Metrics/ParameterLists
                   user_agent:, send_platform_info:, app_info:)
      @auth_key = auth_key
      @host = host
      @max_network_retries = max_network_retries
      @timeout = timeout
      @logger = logger
      @headers = headers
      @user_agent = user_agent || construct_user_agent(send_platform_info, app_info)
    end

    def attributes
      ATTRIBUTES.to_h { |attr| [attr, send(attr)] }
    end

    def ==(other)
      other.is_a?(Configuration) && attributes == other.attributes
    end

    # Redacts the auth key, so that it never shows in the inspect output of objects holding the
    # configuration.
    def inspect
      shown = attributes.merge(auth_key: auth_key.nil? ? nil : '[REDACTED]')
      "#<#{self.class.name} #{shown.map { |name, value| "#{name}=#{value.inspect}" }.join(', ')}>"
    end

    private

    def construct_user_agent(send_platform_info, app_info)
      library_info_str = "deepl-ruby/#{DeepL::VERSION}"
      if send_platform_info
        library_info_str += " (#{RbConfig::CONFIG['host_os']}) ruby/#{RUBY_VERSION}"
      end
      if app_info&.app_name && app_info.app_version
        library_info_str += " #{app_info.app_name}/#{app_info.app_version}"
      end
      library_info_str
    end
  end
end
