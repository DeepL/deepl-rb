# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL.usage' do
  it 'sends GET /v2/usage and parses the usage' do
    usage = DeepL.usage

    expect(usage.character_count).to be_an(Integer)
    expect(usage.character_limit).to be_an(Integer)
    expect(usage.quota_exceeded?).to be(true).or be(false)
  end
end
