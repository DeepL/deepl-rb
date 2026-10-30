# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::AdminClient do
  subject(:client) { described_class.new(admin_key, max_retries: 2) }

  let(:admin_key) { 'admin-key' }
  let(:admin_headers) do
    { 'Authorization' => "DeepL-Auth-Key #{admin_key}", 'Content-Type' => 'application/json' }
  end
  let(:key_id) { 'ca7d5694-96eb-4263-a9a4-7f7e4211529e:20c2abcf-4c3c-4cd6-8ae8-8bd2a7d4da38' }
  let(:developer_key_json) do
    { key_id: key_id, label: 'developer key prod', creation_time: '2025-07-08T08:15:29.362Z',
      deactivated_time: nil, is_deactivated: false,
      usage_limits: { characters: 5000, speech_to_text_milliseconds: nil,
                      speech_to_speech_milliseconds: 3_600_000 } }
  end
  let(:key) { DeepL::Resources::DeveloperKey.new(developer_key_json.transform_keys(&:to_s), nil, nil) }

  def stub_put(action, body)
    stub_request(:put, url("/v2/admin/developer-keys/#{action}"))
      .with(body: body, headers: admin_headers).to_return(reply(developer_key_json))
  end

  describe '#initialize' do
    it 'rejects an empty admin key' do
      ['', ' ', nil].each do |admin_key|
        expect { described_class.new(admin_key) }.to raise_error(ArgumentError, /must not be empty/)
      end
    end

    it 'uses the admin key and the Pro server regardless of the environment' do # rubocop:disable RSpec/ExampleLength
      env = ENV.to_h.slice('DEEPL_AUTH_KEY', 'DEEPL_SERVER_URL')
      ENV['DEEPL_AUTH_KEY'] = 'environment-key'
      ENV['DEEPL_SERVER_URL'] = 'http://environment.example.test'
      begin
        stub_request(:get, url('/v2/admin/developer-keys')).with(headers: admin_headers)
                                                           .to_return(reply([]))
        stub_request(:get, 'http://localhost:3000/v2/admin/developer-keys').to_return(reply([]))

        client.list_developer_keys
        described_class.new(admin_key, server_url: 'http://localhost:3000').list_developer_keys
      ensure
        %w[DEEPL_AUTH_KEY DEEPL_SERVER_URL].each { |name| ENV.delete(name) }
        ENV.update(env)
      end
    end

    it 'trims the admin key' do
      stub_request(:get, url('/v2/admin/developer-keys')).with(headers: admin_headers)
                                                         .to_return(reply([]))

      described_class.new("  #{admin_key}\n").list_developer_keys
    end

    it 'sends the app info and the configured headers' do
      stub_request(:get, url('/v2/admin/developer-keys'))
        .with(headers: { 'X-Custom' => 'v',
                         'User-Agent' => %r{\Adeepl-ruby/[^ ]+ my-app/1\.2\z} })
        .to_return(reply([]))

      described_class.new(admin_key, send_platform_info: false, headers: { 'X-Custom' => 'v' },
                                     app_info: DeepL::AppInfo.new(app_name: 'my-app',
                                                                  app_version: '1.2'))
                     .list_developer_keys
    end

    it 'applies the HTTP client options' do
      options = DeepL::HTTPClientOptions.new({}, nil, read_timeout: 7)
      admin_client = described_class.new(admin_key, http_client_options: options)
      expect(admin_client.send(:api).http_client.read_timeout).to eq(7)
    end

    it 'enables SSL from the URL scheme and verifies certificates unless disabled' do
      build = lambda do |host, verify|
        options = DeepL::HTTPClientOptions.new(nil, nil, enable_ssl_verification: verify)
        described_class.new(admin_key, server_url: host, http_client_options: options)
                       .send(:api).http_client
      end

      expect(build.call('https://api.deepl.com', true)).to have_attributes(use_ssl?: true,
                                                                           verify_mode: nil)
      expect(build.call('https://api.deepl.com', false))
        .to have_attributes(use_ssl?: true, verify_mode: OpenSSL::SSL::VERIFY_NONE)
      expect(build.call('http://localhost:3000', false)).to have_attributes(use_ssl?: false)
    end
  end

  describe '#get_usage_analytics' do
    let(:report_json) do
      { usage_report: {
        total_usage: { total_characters: 9619, text_translation_characters: 4892,
                       document_translation_characters: 0, text_improvement_characters: 4727,
                       speech_to_text_minutes: 107.46 },
        group_by: 'key_and_day', start_date: '2025-09-29T00:00:00',
        end_date: '2025-10-01T00:00:00',
        key_and_day_usages: [
          { api_key: 'dc88****3a2c', api_key_label: 'Staging API Key',
            usage_date: '2025-09-29T00:00:00Z',
            usage: { total_characters: 315, text_improvement_characters: 156,
                     speech_to_text_minutes: 11.94 } }
        ]
      } }
    end

    it 'sends the date range and grouping' do
      stub_request(:get, url('/v2/admin/analytics'))
        .with(query: { start_date: '2025-09-29', end_date: '2025-10-01', group_by: 'key_and_day' },
              headers: admin_headers)
        .to_return(reply(report_json))

      client.get_usage_analytics(Date.new(2025, 9, 29), '2025-10-01',
                                 group_by: DeepL::Constants::AdminUsageGroupBy::KEY_AND_DAY)
    end

    it 'parses the report, reading timestamps without a zone as UTC' do
      stub_request(:get, url('/v2/admin/analytics')).with(query: hash_including({}))
                                                    .to_return(reply(report_json))
      report = client.get_usage_analytics('2025-09-29', '2025-10-01')

      expect(report.total_usage.total_characters).to eq(9619)
      expect([report.start_date, report.key_usages]).to eq([Time.utc(2025, 9, 29), []])
      expect(report.key_and_day_usages.first).to have_attributes(
        api_key_label: 'Staging API Key', usage_date: Time.utc(2025, 9, 29)
      )
    end

    it 'sends the UTC date of a Time or DateTime, without changing it' do
      stub_request(:get, url('/v2/admin/analytics'))
        .with(query: { start_date: '2025-09-28', end_date: '2025-10-02' })
        .to_return(reply(report_json))
      start_time = Time.new(2025, 9, 29, 1, 0, 0, '+02:00')
      end_time = DateTime.new(2025, 10, 1, 23, 0, 0, '-02:00')

      client.get_usage_analytics(start_time, end_time.freeze)

      expect(start_time).to eq(Time.new(2025, 9, 29, 1, 0, 0, '+02:00'))
      expect(start_time.utc_offset).to eq(7200)
      expect(end_time.offset).to eq(Rational(-1, 12))
    end

    it 'sends local midnight in UTC+2 as the previous day' do
      stub_request(:get, url('/v2/admin/analytics'))
        .with(query: { start_date: '2026-10-19', end_date: '2026-10-20' })
        .to_return(reply(report_json))

      client.get_usage_analytics(Time.new(2026, 10, 20, 0, 0, 0, '+02:00'),
                                 DateTime.new(2026, 10, 21, 0, 30, 0, '+02:00'))
    end

    it 'sends a Date as is' do
      stub_request(:get, url('/v2/admin/analytics'))
        .with(query: { start_date: '2026-10-20', end_date: '2026-10-21' })
        .to_return(reply(report_json))

      client.get_usage_analytics(Date.new(2026, 10, 20), '2026-10-21')
    end

    it 'accepts a frozen Time' do
      stub_request(:get, url('/v2/admin/analytics'))
        .with(query: { start_date: '2025-09-28', end_date: '2025-10-01' })
        .to_return(reply(report_json))

      client.get_usage_analytics(Time.new(2025, 9, 29, 1, 0, 0, '+02:00').freeze, '2025-10-01')
    end

    it 'leaves a rejected date range to the API' do
      stub_request(:get, url('/v2/admin/analytics'))
        .with(query: { start_date: '2025-10-01', end_date: '2025-10-01' })
        .to_return(reply({ message: 'start_date must be before end_date' }, 400))

      expect { client.get_usage_analytics('2025-10-01', '2025-10-01') }
        .to raise_error(DeepL::Exceptions::BadRequest)
    end

    it 'reads an absent speech_to_speech_minutes as nil' do
      body = { usage_report: {
        total_usage: { speech_to_speech_minutes: 1.5 },
        key_usages: [{ api_key: 'dc88****3a2c', usage: { total_characters: 3 } }]
      } }
      stub_request(:get, url('/v2/admin/analytics')).with(query: hash_including({}))
                                                    .to_return(reply(body))

      report = client.get_usage_analytics('2025-09-29', '2025-10-01')

      expect(report.total_usage.speech_to_speech_minutes).to eq(1.5)
      expect(report.key_usages.first.usage.speech_to_speech_minutes).to be_nil
    end

    it 'reads an absent total_usage as nil' do
      body = { usage_report: { start_date: '2025-09-29T00:00:00' } }
      stub_request(:get, url('/v2/admin/analytics')).with(query: hash_including({}))
                                                    .to_return(reply(body))

      report = client.get_usage_analytics('2025-09-29', '2025-10-01')

      expect(report.total_usage).to be_nil
    end

    it 'tolerates malformed values in the report' do # rubocop:disable RSpec/ExampleLength
      body = { usage_report: {
        total_usage: { total_characters: 12, speech_to_text_minutes: 'many' },
        start_date: 'not a timestamp', end_date: 5, group_by: 'keyAndDay',
        key_and_day_usages: [
          'bad entry', nil,
          { usage_date: 'not a timestamp', usage: 'oops' },
          { api_key: 'dc88****3a2c', usage: { total_characters: 3 } }
        ]
      } }
      stub_request(:get, url('/v2/admin/analytics')).with(query: hash_including({}))
                                                    .to_return(reply(body))

      report = client.get_usage_analytics('2025-09-29', '2025-10-01')

      expect(report).to have_attributes(start_date: nil, end_date: nil, group_by: 'keyAndDay',
                                        key_usages: [])
      expect(report.total_usage).to have_attributes(total_characters: 12,
                                                    speech_to_text_minutes: 0.0)
      expect(report.key_and_day_usages.map { |usage| [usage.api_key, usage.api_key_label] })
        .to eq([['', nil], ['dc88****3a2c', nil]])
      expect(report.key_and_day_usages.map(&:usage_date)).to eq([nil, nil])
      expect(report.key_and_day_usages.last.usage.total_characters).to eq(3)
    end

    {
      'a date that is not YYYY-MM-DD' => ['2025-9-29', '2025-10-01', /Invalid date/],
      'a date with a time' => ['2025-09-29T00:00:00Z', '2025-10-01', /Invalid date/],
      'a date that does not exist' => ['2025-02-30', '2025-10-01', /Invalid date/],
      'a date of another type' => [20_250_929, '2025-10-01', /Invalid date/]
    }.each do |description, (start_date, end_date, message)|
      it "rejects #{description} before sending a request" do
        expect { client.get_usage_analytics(start_date, end_date) }
          .to raise_error(ArgumentError, message)
      end
    end
  end

  describe '#get_custom_tag_usage_analytics' do
    let(:report_json) do
      { custom_tag_usage_report: {
        aggregate_by: 'day', start_date: '2026-05-03T00:00:00', end_date: '2026-05-15T00:00:00',
        next_page: 3,
        usage: [{ custom_tag: 'example-custom-tag', usage_date: '2026-05-04T00:00:00Z',
                  breakdown: { total_characters: 380, speech_to_speech_minutes: 4.2 } }]
      } }
    end

    it 'sends the date range, aggregation and page' do
      stub_request(:get, url('/v2/admin/analytics/custom-tags'))
        .with(query: { start_date: '2026-05-03', end_date: '2026-05-15', aggregate_by: 'day',
                       page: '2' })
        .to_return(reply(report_json))

      client.get_custom_tag_usage_analytics(Time.utc(2026, 5, 3, 12, 30), Date.new(2026, 5, 15),
                                            aggregate_by: :day, page: 2)
    end

    it 'parses the report' do
      stub_request(:get, url('/v2/admin/analytics/custom-tags')).with(query: hash_including({}))
                                                                .to_return(reply(report_json))
      report = client.get_custom_tag_usage_analytics('2026-05-03', '2026-05-15')

      expect(report).to have_attributes(aggregate_by: 'day', next_page: 3,
                                        start_date: Time.utc(2026, 5, 3))
      expect(report.usage.first).to have_attributes(custom_tag: 'example-custom-tag',
                                                    usage_date: Time.utc(2026, 5, 4))
      expect(report.usage.first.breakdown).to have_attributes(speech_to_speech_minutes: 4.2,
                                                              speech_to_text_minutes: 0.0)
    end

    it 'reads an absent speech_to_speech_minutes as nil' do
      body = { custom_tag_usage_report: {
        usage: [{ custom_tag: 'tag', breakdown: { total_characters: 380 } }]
      } }
      stub_request(:get, url('/v2/admin/analytics/custom-tags')).with(query: hash_including({}))
                                                                .to_return(reply(body))

      report = client.get_custom_tag_usage_analytics('2026-05-03', '2026-05-15')

      expect(report.usage.first.breakdown.speech_to_speech_minutes).to be_nil
    end

    it 'rejects an invalid date like the usage analytics' do
      expect { client.get_custom_tag_usage_analytics('2025-9-1', '2025-09-01') }
        .to raise_error(ArgumentError, /Invalid date/)
    end

    it 'tolerates malformed values in the report' do # rubocop:disable RSpec/ExampleLength
      body = { custom_tag_usage_report: {
        aggregate_by: 'day', start_date: 'not a timestamp', next_page: nil,
        usage: ['bad entry', { usage_date: 'x', breakdown: [] },
                { custom_tag: 'tag', breakdown: { total_characters: 'many',
                                                  speech_to_speech_minutes: 4.2 } }]
      } }
      stub_request(:get, url('/v2/admin/analytics/custom-tags')).with(query: hash_including({}))
                                                                .to_return(reply(body))

      report = client.get_custom_tag_usage_analytics('2026-05-03', '2026-05-15')

      expect(report).to have_attributes(aggregate_by: 'day', start_date: nil, next_page: nil)
      expect(report.usage.map(&:custom_tag)).to eq(['', 'tag'])
      expect(report.usage.last.breakdown).to have_attributes(total_characters: 0,
                                                             speech_to_speech_minutes: 4.2)
    end
  end

  describe '#create_developer_key' do
    def stub_create
      stub_request(:post, url('/v2/admin/developer-keys'))
    end

    it 'posts the label and parses the key' do
      stub_create.with(body: { label: 'developer key prod' }.to_json, headers: admin_headers)
                 .to_return(reply(developer_key_json))

      key = client.create_developer_key(label: 'developer key prod')

      expect(key).to have_attributes(key_id: key_id, label: 'developer key prod',
                                     creation_time: Time.utc(2025, 7, 8, 8, 15, 29.362r),
                                     deactivated_time: nil, deactivated?: false)
      expect(key.usage_limits).to have_attributes(characters: 5000,
                                                  speech_to_text_milliseconds: nil,
                                                  speech_to_speech_milliseconds: 3_600_000)
    end

    it 'posts an empty body without a label' do
      stub_create.with(body: '{}').to_return(reply(developer_key_json))

      client.create_developer_key
    end

    it 'adds the extra body parameters last' do
      stub_create.with(body: { label: 'replaced', extra: [1] }.to_json)
                 .to_return(reply(developer_key_json))

      client.create_developer_key(label: 'given',
                                  extra_body_parameters: { label: 'replaced', extra: [1] })
    end

    it 'raises when the response has no key_id' do
      stub_create.to_return(reply(developer_key_json.reject { |k, _| k == :key_id }))

      expect { client.create_developer_key }
        .to raise_error(DeepL::Exceptions::Error, /missing key_id/)
    end

    it 'raises when the response is not a JSON object' do
      stub_create.to_return(reply([developer_key_json]))

      expect { client.create_developer_key }.to raise_error(DeepL::Exceptions::Error)
    end

    it 'retries after a 429 reply' do
      stub = stub_create.to_return(reply({}, 429), reply(developer_key_json))

      client.create_developer_key

      expect(stub).to have_been_requested.twice
    end

    it 'retries after a DNS resolution error' do
      stub = stub_create.to_raise(SocketError).then.to_return(reply(developer_key_json))

      client.create_developer_key

      expect(stub).to have_been_requested.twice
    end

    it 'retries after a connection timeout' do
      stub = stub_create.to_raise(Net::OpenTimeout).then.to_return(reply(developer_key_json))

      client.create_developer_key

      expect(stub).to have_been_requested.twice
    end

    it 'retries after a refused connection' do
      stub = stub_create.to_raise(Errno::ECONNREFUSED).then.to_return(reply(developer_key_json))

      client.create_developer_key

      expect(stub).to have_been_requested.twice
    end

    it 'does not retry a 500 or 503 reply' do
      [500, 503].each do |status|
        WebMock.reset!
        stub = stub_create.to_return(reply({ message: 'Error' }, status))

        expect { client.create_developer_key }.to raise_error(DeepL::Exceptions::Error)
        expect(stub).to have_been_requested.once
      end
    end

    it 'does not retry a read timeout or a connection reset' do
      [Net::ReadTimeout, Errno::ECONNRESET].each do |error|
        WebMock.reset!
        stub = stub_create.to_raise(error)

        expect { client.create_developer_key }
          .to raise_error(DeepL::Exceptions::ConnectionError) { |e| expect(e.cause).to be_a(error) }
        expect(stub).to have_been_requested.once
      end
    end

    it 'does not retry a body shorter than its Content-Length' do
      short = { status: 200, body: '{"api', headers: { 'Content-Length' => '99' } }
      stub = stub_create.to_return(short)

      expect { client.create_developer_key }
        .to raise_error(DeepL::Exceptions::ConnectionError) { |e| expect(e.should_retry?).to be(true) }
      expect(stub).to have_been_requested.once
    end
  end

  describe '#list_developer_keys' do
    it 'parses all keys and retries a 500 reply' do
      deactivated = developer_key_json.merge(is_deactivated: true,
                                             deactivated_time: '2025-07-09T08:15:29Z')
      stub = stub_request(:get, url('/v2/admin/developer-keys'))
             .with(body: nil, headers: admin_headers)
             .to_return(reply({}, 500), reply([developer_key_json, deactivated]))

      keys = client.list_developer_keys

      expect(stub).to have_been_requested.twice
      expect(keys.map(&:deactivated?)).to eq([false, true])
      expect(keys.last.deactivated_time).to eq(Time.utc(2025, 7, 9, 8, 15, 29))
    end
  end

  describe 'malformed developer keys' do
    it 'skips list entries that are not objects or lack a key_id, and fills in neutral defaults' do # rubocop:disable RSpec/ExampleLength
      body = [1, { label: 'no id' },
              { key_id: key_id, creation_time: 'not a timestamp', usage_limits: 'none',
                is_deactivated: 'false' },
              developer_key_json.merge(key_id: 'second', label: 'ok', is_deactivated: nil)]
      stub_request(:get, url('/v2/admin/developer-keys')).to_return(reply(body))

      keys = client.list_developer_keys

      expect(keys.map(&:label)).to eq([nil, 'ok'])
      expect(keys.first).to have_attributes(key_id: key_id, creation_time: nil,
                                            is_deactivated: false, usage_limits: nil)
      expect(keys.last).to have_attributes(is_deactivated: false)
      expect(keys.last.creation_time).to eq(Time.utc(2025, 7, 8, 8, 15, 29.362r))
    end

    it 'raises when the list is not an array' do
      stub_request(:get, url('/v2/admin/developer-keys')).to_return(reply(developer_key_json))

      expect { client.list_developer_keys }.to raise_error(DeepL::Exceptions::Error)
    end

    it 'raises when an analytics response is not a JSON object' do
      stub_request(:get, url('/v2/admin/analytics')).with(query: hash_including({}))
                                                    .to_return(reply([]))

      expect { client.get_usage_analytics('2025-09-29', '2025-10-01') }
        .to raise_error(DeepL::Exceptions::Error)
    end
  end

  describe 'modifying developer keys' do
    it 'deactivates and renames by key or key ID' do
      stub_put('deactivate', key_id: key_id)
      stub_put('label', key_id: key_id, label: 'renamed')

      client.deactivate_developer_key(key)
      client.rename_developer_key(key_id, 'renamed')
    end

    it 'sends only the given usage limits, including explicit nulls' do
      stub_put('limits', key_id: key_id, characters: 0)
      stub_put('limits', key_id: key_id, speech_to_text_milliseconds: nil,
                         speech_to_speech_milliseconds: 60_000)

      client.set_developer_key_usage_limits(key, characters: 0)
      client.set_developer_key_usage_limits(key_id, speech_to_text_milliseconds: nil,
                                                    speech_to_speech_milliseconds: 60_000)
    end

    it 'adds the extra body parameters last, apart from the usage limits' do
      stub_put('deactivate', key_id: key_id, extra: true)
      stub_put('label', key_id: key_id, label: 'replaced')
      stub_put('limits', key_id: key_id, characters: 0, extra: nil)

      client.deactivate_developer_key(key, extra_body_parameters: { extra: true })
      client.rename_developer_key(key, 'given', extra_body_parameters: { label: 'replaced' })
      client.set_developer_key_usage_limits(key, characters: 0,
                                                 extra_body_parameters: { extra: nil })
    end

    it 'sends the given key even if the limits contain a key_id' do
      stub_put('limits', key_id: key_id, characters: 0)

      client.set_developer_key_usage_limits(key, characters: 0, key_id: 'other')
      expect { client.set_developer_key_usage_limits('', key_id: 'other') }
        .to raise_error(ArgumentError, /key ID/)
    end

    it 'rejects an empty key ID before sending a request' do
      expect { client.deactivate_developer_key('') }.to raise_error(ArgumentError, /key ID/)
      expect { client.rename_developer_key(nil, 'renamed') }.to raise_error(ArgumentError, /key ID/)
      expect { client.set_developer_key_usage_limits(nil, characters: 1) }
        .to raise_error(ArgumentError, /key ID/)
    end
  end

  it 'raises an authorization error on a 403 reply' do
    stub_request(:get, url('/v2/admin/developer-keys'))
      .to_return(reply({ message: 'Forbidden' }, 403))

    expect { client.list_developer_keys }.to raise_error(DeepL::Exceptions::AuthorizationFailed)
  end
end
