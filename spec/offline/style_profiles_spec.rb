# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::StyleProfileApi do
  let(:style_profiles) { DeepL.style_profiles }
  let(:profile_id) { '3f1c9d0e-7a24-4b58-9c31-8f0e5d2a1b47' }
  let(:profile_path) { "/v3/style_profiles/#{profile_id}" }
  # The full example of the API specification.
  let(:profile_json) do
    { style_profile_id: profile_id, name: 'Legal, German',
      description: 'Contract wording for the German market.', industry: 'Legal',
      glossary_ids: ['4d0a2e1c-6b93-4f7a-8d15-2c6e9a3b7f81'],
      style_rule_ids: ['bd0a38f3-1831-440b-a8dd-2c702e2325ab'],
      translation_memory_ids: ['a74d88fb-ed2a-4943-a664-a4512398b994'],
      glossary_priority_order_enabled: true,
      creation_time: '2026-04-01T16:34:25.223Z', updated_time: '2026-08-06T09:12:44.108Z' }
  end
  let(:bare_profile_json) do
    { style_profile_id: 'c58e2a71-90b4-4d6f-a2e3-71d5c8b4f902', name: 'Marketing, Japanese',
      glossary_ids: [], style_rule_ids: [], translation_memory_ids: [],
      glossary_priority_order_enabled: false,
      creation_time: '2026-07-14T11:02:09.640Z', updated_time: '2026-07-14T11:02:09.640Z' }
  end

  def profile_object
    DeepL::Resources::StyleProfile.new(profile_json.transform_keys(&:to_s), nil, nil)
  end

  describe '#list' do
    it 'sends no query without paging options and returns the profiles as an array' do
      list_json = { style_profiles: [profile_json, bare_profile_json], total_count: 2 }
      stub_request(:get, url('/v3/style_profiles')).with(headers: json_headers)
                                                   .to_return(reply(list_json))

      profiles = style_profiles.list

      expect(profiles.map(&:name)).to eq(['Legal, German', 'Marketing, Japanese'])
    end

    it 'sends page and page_size as query parameters' do
      stub_request(:get, url('/v3/style_profiles?page=2&page_size=100'))
        .to_return(reply(style_profiles: [], total_count: 0))

      expect(style_profiles.list(page: 2, page_size: 100)).to eq([])
    end

    it 'returns an empty array when style_profiles is missing' do
      stub_request(:get, url('/v3/style_profiles')).to_return(reply(total_count: 0))

      expect(style_profiles.list).to eq([])
    end
  end

  describe '#create' do
    it 'sends only the name when no component is given' do
      stub_request(:post, url('/v3/style_profiles'))
        .with(body: { name: 'profile' }.to_json, headers: json_headers)
        .to_return(reply(bare_profile_json, 201))

      style_profiles.create('profile')
    end

    it 'sends every field, the ID arrays in order and the boolean as JSON true' do
      body = { name: 'profile', description: 'd', industry: 'Legal',
               glossary_ids: %w[g2 g1], style_rule_ids: %w[s1], translation_memory_ids: %w[t1],
               glossary_priority_order_enabled: true }
      stub_request(:post, url('/v3/style_profiles'))
        .with { |request| JSON.parse(request.body) == JSON.parse(body.to_json) }
        .to_return(reply(profile_json, 201))

      style_profiles.create('profile', description: 'd', industry: 'Legal',
                                       glossary_ids: %w[g2 g1], style_rule_ids: %w[s1],
                                       translation_memory_ids: %w[t1],
                                       glossary_priority_order_enabled: true)
    end

    it 'applies extra body parameters' do
      stub_request(:post, url('/v3/style_profiles'))
        .with(body: { name: 'profile', beta: 'x' }.to_json)
        .to_return(reply(bare_profile_json, 201))

      style_profiles.create('profile', extra_body_parameters: { beta: 'x' })
    end
  end

  describe '#find' do
    it 'accepts an ID string or a style profile object' do
      stub_request(:get, url(profile_path)).with(headers: json_headers)
                                           .to_return(reply(profile_json)).times(2)

      expect(style_profiles.find(profile_id).id).to eq(profile_id)
      expect(style_profiles.find(profile_object).id).to eq(profile_id)
    end

    it 'escapes the ID in the path' do
      stub_request(:get, url('/v3/style_profiles/a%2Fb%20c')).to_return(reply(profile_json))

      style_profiles.find('a/b c')
    end

    it 'raises NotFound on 404' do
      stub_request(:get, url(profile_path))
        .to_return(reply({ message: 'Style profile not found' }, 404))

      expect { style_profiles.find(profile_id) }.to raise_error(DeepL::Exceptions::NotFound)
    end
  end

  describe '#update' do
    it 'sends only the set fields, including an empty string and an empty array' do
      stub_request(:patch, url(profile_path))
        .with(body: { name: 'new', description: '', style_rule_ids: [] }.to_json,
              headers: json_headers)
        .to_return(reply(profile_json))

      style_profiles.update(profile_id, name: 'new', description: '', style_rule_ids: [])
    end

    it 'sends an empty object when nothing is set, also for a style profile object' do
      stub_request(:patch, url(profile_path)).with(body: '{}').to_return(reply(profile_json))
                                             .times(2)

      style_profiles.update(profile_id)
      style_profiles.update(profile_object)
    end

    it 'sends glossary_priority_order_enabled false as JSON false' do
      stub_request(:patch, url(profile_path))
        .with(body: { glossary_priority_order_enabled: false }.to_json)
        .to_return(reply(profile_json))

      style_profiles.update(profile_id, glossary_priority_order_enabled: false)
    end
  end

  describe '#destroy' do
    it 'sends DELETE for an ID string or a style profile object and returns the ID' do
      stub_request(:delete, url(profile_path)).with(headers: json_headers)
                                              .to_return(status: 204).times(2)

      expect(style_profiles.destroy(profile_id)).to eq(profile_id)
      expect(style_profiles.destroy(profile_object)).to eq(profile_id)
    end
  end

  describe 'empty ID' do
    it 'raises ArgumentError and sends no request' do
      ['', nil].each do |id|
        expect { style_profiles.find(id) }.to raise_error(ArgumentError)
        expect { style_profiles.update(id, name: 'x') }.to raise_error(ArgumentError)
        expect { style_profiles.destroy(id) }.to raise_error(ArgumentError)
      end
      expect(a_request(:any, /.*/)).not_to have_been_made
    end
  end

  describe 'parsing' do
    it 'parses every field of the specification example' do
      stub_request(:get, url(profile_path)).to_return(reply(profile_json))

      times = { creation_time: Time.utc(2026, 4, 1, 16, 34, Rational(25_223, 1000)),
                updated_time: Time.utc(2026, 8, 6, 9, 12, Rational(44_108, 1000)) }
      expected = profile_json.reject { |key, _| key == :style_profile_id }
                             .merge(times, id: profile_id)
      expect(style_profiles.find(profile_id)).to have_attributes(expected)
    end

    it 'parses a profile without description and industry, and ignores unknown fields' do
      stub_request(:get, url(profile_path)).to_return(
        reply(bare_profile_json.merge(example_document_ids: ['e1'], spoken_terms_ids: ['s1']))
      )

      profile = style_profiles.find(profile_id)

      expect(profile.description).to be_nil
      expect(profile.industry).to be_nil
      expect(profile.glossary_priority_order_enabled).to be(false)
      expect(profile).not_to respond_to(:example_document_ids)
      expect(profile).not_to respond_to(:spoken_terms_ids)
    end

    it 'parses a timestamp with 7 fractional digits' do
      stub_request(:get, url(profile_path))
        .to_return(reply(bare_profile_json.merge(creation_time: '2026-10-26T16:27:10.2982869Z')))

      expect(style_profiles.find(profile_id).creation_time)
        .to eq(Time.utc(2026, 10, 26, 16, 27, Rational(102_982_869, 10_000_000)))
    end

    it 'defaults missing ID lists and the boolean' do
      stub_request(:get, url(profile_path))
        .to_return(reply(style_profile_id: profile_id, name: 'n', glossary_ids: nil))

      profile = style_profiles.find(profile_id)

      expect([profile.glossary_ids, profile.style_rule_ids, profile.translation_memory_ids])
        .to eq([[], [], []])
      expect(profile.glossary_priority_order_enabled).to be(false)
    end

    it 'turns malformed values into nil or skips them without failing the call' do
      stub_request(:get, url(profile_path)).to_return(
        reply(profile_json.merge(creation_time: 'not a timestamp', glossary_ids: ['g1', 7, nil]))
      )

      profile = style_profiles.find(profile_id)

      expect(profile.creation_time).to be_nil
      expect(profile.glossary_ids).to eq(['g1'])
      expect(profile.name).to eq('Legal, German')
      expect(profile.style_rule_ids).to eq(['bd0a38f3-1831-440b-a8dd-2c702e2325ab'])
      expect(profile.updated_time).to eq(Time.utc(2026, 8, 6, 9, 12, Rational(44_108, 1000)))
    end
  end
end
