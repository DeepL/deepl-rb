# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL error mapping' do
  {
    401 => [DeepL::Exceptions::AuthorizationFailed, /Authorization failed/],
    403 => [DeepL::Exceptions::AuthorizationFailed, /Authorization failed/],
    456 => [DeepL::Exceptions::QuotaExceeded, /Quota exceeded/],
    413 => [DeepL::Exceptions::RequestEntityTooLarge,
            /request size has reached the supported limit/],
    503 => [DeepL::Exceptions::ServerError, /internal server error/],
    418 => [DeepL::Exceptions::RequestError, 'Unknown error.']
  }.each do |status, (error_class, message)|
    it "raises #{error_class.name.split('::').last} for status #{status} without retrying" do
      stub = stub_request(:get, url('/v2/usage')).to_return(status: status, body: '{"message":"m"}')

      expect { DeepL.usage }.to raise_error(error_class, message)
      expect(stub).to have_been_requested.once
    end
  end

  {
    400 => DeepL::Exceptions::BadRequest,
    404 => DeepL::Exceptions::NotFound
  }.each do |status, error_class|
    it "raises #{error_class.name.split('::').last} with the API message for status #{status}" do
      stub = stub_request(:get,
                          url('/v2/usage')).to_return(reply({ message: 'Value for x invalid' },
                                                            status))

      expect { DeepL.usage }.to raise_error(error_class, 'Value for x invalid')
      expect(stub).to have_been_requested.once
    end

    it "raises #{error_class.name.split('::').last} with a plain-text body as the message" do
      stub_request(:get, url('/v2/usage')).to_return(status: status, body: 'plain text')

      expect { DeepL.usage }.to raise_error(error_class, 'plain text')
    end
  end

  it 'keeps the response on the raised error' do
    stub_request(:get, url('/v2/usage')).to_return(status: 456, body: 'quota')

    expect { DeepL.usage }.to(raise_error { |error| expect(error.response.body).to eq('quota') })
  end

  it 'raises the errors of every endpoint family the same way' do
    stub_request(:post, %r{/v2/(translate|write/correct)}).to_return(status: 403)
    stub_request(:delete, url('/v3/glossaries/g-1')).to_return(status: 404,
                                                               body: '{"message":"gone"}')

    expect { DeepL.translate('a', nil, 'DE') }.to raise_error(DeepL::Exceptions::AuthorizationFailed)
    expect { DeepL.correct('a') }.to raise_error(DeepL::Exceptions::AuthorizationFailed)
    expect do
      DeepL.multilingual_glossaries.destroy('g-1')
    end.to raise_error(DeepL::Exceptions::NotFound, 'gone')
  end
end
