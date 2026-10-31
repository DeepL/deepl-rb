# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client#correct_text' do
  let(:client) do
    DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  end

  it 'sends POST /v2/write/correct and parses the result' do
    result = client.correct_text('Protonenstrahl', 'de')

    expect(result).to be_a(DeepL::Resources::Text)
    expect(result.text).to be_a(String)
    expect(result.detected_source_language).not_to be_empty
  end
end
