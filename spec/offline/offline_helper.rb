# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

if defined?(RealApiHelper)
  raise 'spec/offline and spec/real_api cannot run in one process: WebMock blocks the network'
end

require_relative '../spec_helper'
require_relative '../fixtures'
require 'webmock/rspec'

# The offline suite never touches the network: every request is declared with WebMock and
# asserted exactly.
WebMock.disable_net_connect!

module OfflineHelper
  HOST = 'https://api.deepl.com'
  AUTH_KEY = 'k'

  def url(path)
    "#{HOST}#{path}"
  end

  # Headers of a request with a JSON Content-Type.
  def json_headers
    { 'Authorization' => "DeepL-Auth-Key #{AUTH_KEY}", 'Content-Type' => 'application/json' }
  end

  # Headers of a request without a body.
  def auth_headers
    { 'Authorization' => "DeepL-Auth-Key #{AUTH_KEY}" }
  end

  # True for a request sent without a body and without a Content-Type, as GET and DELETE are.
  def bodyless?(request)
    request.body.to_s.empty? && !request.headers.key?('Content-Type')
  end

  def reply(body = {}, status = 200)
    { status: status, body: body.is_a?(String) ? body : body.to_json }
  end

  def usage_reply
    reply(character_count: 1, character_limit: 10)
  end
end

RSpec.configure do |config|
  config.include OfflineHelper
  config.include Fixtures

  config.before do
    DeepL.configure do |c|
      c.auth_key = OfflineHelper::AUTH_KEY
      c.host = OfflineHelper::HOST
      c.logger = nil
      c.max_doc_status_queries = nil
      c.headers = {}
      # The default of 5 retries would sleep for about 16 seconds in every retry example.
      c.max_network_retries = 2
    end
  end

  # A declared request that the SDK never sent is a failure. webmock/rspec resets the stubs
  # in an around hook, which runs after this one.
  config.after do
    expect(WebMock::StubRegistry.instance.request_stubs).to all(have_been_requested.at_least_once)
  end
end
