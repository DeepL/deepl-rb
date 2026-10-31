# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL do
  it 'has no module-level methods for the operations added after 3.9.0' do
    expect(%i[correct language_resources languages_for_resource multilingual_glossaries]
             .map { |name| described_class.respond_to?(name) }).to eq([false] * 4)
  end
end
