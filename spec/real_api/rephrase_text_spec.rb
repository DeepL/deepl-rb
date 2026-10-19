# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL.rephrase' do
  it 'sends POST /v2/write/rephrase and parses the result' do
    result = DeepL.rephrase('Protonenstrahl', 'de')

    expect(result).to be_a(DeepL::Resources::Text)
    expect(result.text).to be_a(String)
    expect(result.detected_source_language).not_to be_empty
  end
end
