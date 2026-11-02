# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client#translate_document' do
  include_context 'with a temporary directory'

  it 'uploads, polls and downloads a .txt document' do
    input, output = create_text_document(temp_dir)

    status = real_api_client.translate_document(input, output, 'EN', 'DE')

    expect(status.done?).to be(true)
    expect(File.size(output)).to be_positive
  end
end
