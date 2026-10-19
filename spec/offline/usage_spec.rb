# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL.usage' do
  it 'sends a GET with an empty JSON body' do
    stub_request(:get, url('/v2/usage')).with(body: '{}', headers: json_headers)
                                        .to_return(usage_reply)
    DeepL.usage
  end

  it 'reports no exceeded quota while the count is below the limit' do
    stub_request(:get, url('/v2/usage')).to_return(reply(character_count: 42, character_limit: 100))

    expect(DeepL.usage.quota_exceeded?).to be(false)
  end

  it 'reports an exceeded quota when the count reaches the limit' do
    stub_request(:get,
                 url('/v2/usage')).to_return(reply(character_count: 100, character_limit: 100))

    expect(DeepL.usage.quota_exceeded?).to be(true)
  end
end
