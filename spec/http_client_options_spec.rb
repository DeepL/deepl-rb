# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::HTTPClientOptions do
  describe '#initialize' do
    context 'when initialized without arguments' do
      it 'sets default values' do
        options = DeepL::HTTPClientOptions.new
        expect(options.proxy).to eq({})
        expect(options.cert_path).to be_nil
        expect(options.enable_ssl_verification).to be true
        expect(options.open_timeout).to be_nil
        expect(options.read_timeout).to be_nil
        expect(options.write_timeout).to be_nil
        expect(options.ssl_timeout).to be_nil
      end
    end

    context 'when initialized with all parameters' do
      it 'sets all attributes correctly' do
        proxy = { 'proxy_addr' => 'proxy.example.com', 'proxy_port' => 8080 }
        cert_path = '/path/to/cert.pem'
        options = DeepL::HTTPClientOptions.new(
          proxy,
          cert_path,
          enable_ssl_verification: false,
          open_timeout: 5,
          read_timeout: 10,
          write_timeout: 15,
          ssl_timeout: 20
        )
        expect(options.proxy).to eq(proxy)
        expect(options.proxy['proxy_addr']).to eq('proxy.example.com')
        expect(options.proxy['proxy_port']).to eq(8080)
        
        expect(options.cert_path).to eq(cert_path)
        expect(options.enable_ssl_verification).to be false
        expect(options.open_timeout).to eq(5)
        expect(options.read_timeout).to eq(10)
        expect(options.write_timeout).to eq(15)
        expect(options.ssl_timeout).to eq(20)
      end
    end

    context 'when initialized with invalid keyword arguments' do
      it 'raises an ArgumentError' do
        expect {
          DeepL::HTTPClientOptions.new({}, nil, invalid_option: true)
        }.to raise_error(ArgumentError)
      end
    end

    context 'attribute readers' do
      it 'does not allow attributes to be modified after initialization' do
        options = DeepL::HTTPClientOptions.new
        expect {
          options.proxy = { 'proxy_addr' => 'new.proxy.com' }
        }.to raise_error(NoMethodError)
      end
    end
  end
end
