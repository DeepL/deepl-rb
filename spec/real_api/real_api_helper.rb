# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

# The real-API suite sends one real request per SDK operation to the API at DEEPL_SERVER_URL.
# Run it on its own: bundle exec rspec spec/real_api

raise 'DEEPL_AUTH_KEY must be set to run spec/real_api' if ENV.fetch('DEEPL_AUTH_KEY', '').empty?
if defined?(WebMock)
  raise 'spec/real_api and spec/offline cannot run in one process: WebMock blocks the network'
end

require 'securerandom'
require_relative '../spec_helper'
require_relative '../fixtures'

module RealApiHelper
  RUN_ID = "#{Time.now.utc.strftime('%Y%m%d%H%M')}-#{SecureRandom.alphanumeric(6).downcase}"

  # Name of a resource created by this run, for example sdktest-ruby-202610151530-k3f9qz-glossary.
  def unique_name(label)
    "sdktest-ruby-#{RUN_ID}-#{label}"
  end

  # A new glossary can be briefly invisible: retry NotFound for a few seconds.
  def retry_while_not_found(attempts: 10)
    tries = 0
    begin
      yield
    rescue DeepL::Exceptions::NotFound
      tries += 1
      raise if tries >= attempts

      sleep(1)
      retry
    end
  end

  # Cleanup that must not hide the failure of the example it runs after.
  def delete_quietly
    yield
  rescue DeepL::Exceptions::Error
    nil
  end

  # Fetches pages of 0-based index until +id+ is in one of them. The block returns the IDs of a
  # page; an empty page ends the list.
  def found_on_any_page?(id, max_pages: 20)
    max_pages.times do |page|
      ids = yield(page)
      return false if ids.empty?
      return true if ids.include?(id)
    end
    false
  end
end

# The host comes from DEEPL_SERVER_URL, which Configuration reads itself.
DeepL.configure { |config| config.auth_key = ENV.fetch('DEEPL_AUTH_KEY') }

RSpec.configure do |config|
  config.include RealApiHelper
  config.include Fixtures
end
