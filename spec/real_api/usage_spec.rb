# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client#get_usage' do
  let(:client) do
    DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  end

  it 'sends GET /v2/usage and parses the usage' do
    usage = client.get_usage

    expect(usage.character.count).to be_an(Integer)
    expect(usage.character.limit).to be_an(Integer)
    expect(usage.any_limit_reached?).to be(true).or be(false)
  end
end
