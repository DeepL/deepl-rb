# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'webrick'
require 'webrick/httpproxy'
require_relative 'real_api_helper'

# A forward proxy that records the target of each CONNECT.
class RecordingProxy < WEBrick::HTTPProxyServer
  def connect_targets
    @connect_targets ||= []
  end

  def do_CONNECT(req, res) # rubocop:disable Naming/MethodName
    connect_targets << req.unparsed_uri
    super
  end
end

describe 'DeepL::Client proxy' do
  it 'sends requests through the configured proxy' do
    proxy = RecordingProxy.new(Port: 0, BindAddress: '127.0.0.1', AccessLog: [],
                               Logger: WEBrick::Log.new(File::NULL))
    thread = Thread.new { proxy.start }
    begin
      port = proxy.listeners.first.addr[1]
      client = real_api_client(proxy: "http://127.0.0.1:#{port}")

      usage = client.get_usage

      host = URI(client.send(:api).configuration.host)
      expect(usage.character.limit).to be_an(Integer)
      expect(proxy.connect_targets).to eq(["#{host.host}:#{host.port}"])
    ensure
      proxy.shutdown
      thread.join
    end
  end
end
