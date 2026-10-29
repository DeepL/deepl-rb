# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe DeepL::AdminClient do
  subject(:client) do
    described_class.new(ENV.fetch('DEEPL_ADMIN_KEY'),
                        server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  end

  before do
    next unless ENV.fetch('DEEPL_ADMIN_KEY', '').empty?

    raise 'DEEPL_ADMIN_KEY must be set to run the Admin API specs'
  end

  let(:end_date) { Time.now.utc.to_date }
  let(:start_date) { end_date - 7 }

  def key_listed?(client, key_id)
    5.times do |attempt|
      return true if client.list_developer_keys.map(&:key_id).include?(key_id)

      sleep 1 unless attempt == 4
    end
    false
  end

  it 'sends GET /v2/admin/analytics and parses the report' do
    report = client.get_usage_analytics(start_date, end_date,
                                        group_by: DeepL::Constants::AdminUsageGroupBy::KEY_AND_DAY)

    expect(report.start_date).not_to be_nil
    expect(report.end_date).not_to be_nil
    expect(report.group_by).to eq('keyAndDay')
  end

  it 'sends GET /v2/admin/analytics/custom-tags and parses the report' do
    report = client.get_custom_tag_usage_analytics(
      start_date, end_date, aggregate_by: DeepL::Constants::CustomTagUsageAggregateBy::DAY
    )

    expect(report.start_date).not_to be_nil
    expect(report.end_date).not_to be_nil
    expect(report.aggregate_by).to eq('day')
  end

  it 'sends the developer key requests: create, list, rename, set limits and deactivate' do
    key = client.create_developer_key(unique_name('developer-key'))
    failure = nil
    begin
      expect(key.deactivated?).to be(false)
      expect(key_listed?(client, key.key_id)).to be(true), 'created key not listed after 5 attempts'
      renamed = client.rename_developer_key(key, "#{key.label}-renamed")
      expect(renamed.label).to eq("#{key.label}-renamed")
      limited = client.set_developer_key_usage_limits(key, characters: 5000,
                                                           speech_to_text_milliseconds: nil)
      expect(limited.usage_limits).to have_attributes(characters: 5000,
                                                      speech_to_text_milliseconds: nil)
    rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
      failure = e
      raise
    ensure
      begin
        deactivated = client.deactivate_developer_key(key)
      rescue DeepL::Exceptions::NotFound
        deactivated = nil
      rescue StandardError
        raise if failure.nil?
      end
    end
    expect(deactivated&.deactivated?).to be(true)
  end
end
