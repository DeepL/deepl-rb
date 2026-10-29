# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client style profiles' do
  let(:client) do
    DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  end

  it 'creates, reads, lists, updates and deletes a style profile' do
    rule = DeepL.style_rules.create(unique_name('styleProfileRule'), 'de')
    rule_id = rule.style_id
    id = nil
    begin
      name = unique_name('styleProfile')
      profile = client.create_style_profile(name, description: 'SDK test', style_rule_ids: [rule])
      id = profile.style_profile_id
      expect([profile.name, profile.description, profile.style_rule_ids])
        .to eq([name, 'SDK test', [rule_id]])
      expect([profile.glossary_ids, profile.translation_memory_ids]).to eq([[], []])

      fetched = retry_while_not_found { client.get_style_profile(id) }
      expect([fetched.style_profile_id, fetched.name, fetched.description, fetched.style_rule_ids])
        .to eq([id, name, 'SDK test', [rule_id]])
      expect(fetched.creation_time).to be_a(Time)

      expect(found_on_any_page?(id) do |page|
        client.list_style_profiles(page: page, page_size: 100).map(&:style_profile_id)
      end).to be(true)

      updated = client.update_style_profile(profile, name: "#{name}-renamed", industry: 'Legal',
                                                     description: '', style_rule_ids: [])
      expect([updated.name, updated.industry, updated.description, updated.style_rule_ids])
        .to eq(["#{name}-renamed", 'Legal', nil, []])

      expect(client.delete_style_profile(id)).to be_nil
      expect { client.get_style_profile(id) }.to raise_error(DeepL::Exceptions::NotFound)
    ensure
      delete_quietly { client.delete_style_profile(id) } if id
      delete_quietly { DeepL.style_rules.destroy(rule_id) }
    end
  end
end
