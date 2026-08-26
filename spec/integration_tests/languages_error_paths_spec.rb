# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe 'DeepL.languages error paths' do # rubocop:disable RSpec/DescribeClass
  include_context 'with a live mock server'

  describe 'authorization failures' do
    it 'raises AuthorizationFailed when the auth key is invalid' do
      request = DeepL::Requests::Languages.new(unauthorized_api)

      expect { request.request }.to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end
  end

  describe 'invalid arguments' do
    it 'raises ArgumentError for an unsupported languages type' do
      expect { DeepL.languages(type: :invalid) }
        .to raise_error(ArgumentError, /Unsupported `type` option/)
    end
  end
end
