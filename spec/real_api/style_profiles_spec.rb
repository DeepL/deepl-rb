# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL.style_profiles' do
  it 'creates, reads, lists, updates and deletes a style profile' do
    style_profiles = DeepL.style_profiles
    rule_id = DeepL.style_rules.create(unique_name('styleProfileRule'), 'de').style_id
    profile = nil
    begin
      name = unique_name('styleProfile')
      profile = style_profiles.create(name, description: 'SDK test', style_rule_ids: [rule_id])
      expect([profile.name, profile.description, profile.style_rule_ids])
        .to eq([name, 'SDK test', [rule_id]])
      expect([profile.glossary_ids, profile.translation_memory_ids]).to eq([[], []])

      fetched = retry_while_not_found { style_profiles.find(profile.id) }
      expect([fetched.id, fetched.name, fetched.description, fetched.style_rule_ids])
        .to eq([profile.id, name, 'SDK test', [rule_id]])
      expect(fetched.creation_time).to be_a(Time)

      expect(found_on_any_page?(profile.id) do |page|
        style_profiles.list(page: page, page_size: 100).map(&:id)
      end).to be(true)

      updated = style_profiles.update(profile, name: "#{name}-renamed", industry: 'Legal',
                                               description: '', style_rule_ids: [])
      expect([updated.name, updated.industry, updated.description, updated.style_rule_ids])
        .to eq(["#{name}-renamed", 'Legal', nil, []])

      style_profiles.destroy(profile.id)
      expect { style_profiles.find(profile.id) }.to raise_error(DeepL::Exceptions::NotFound)
    ensure
      delete_quietly { style_profiles.destroy(profile.id) } if profile
      delete_quietly { DeepL.style_rules.destroy(rule_id) }
    end
  end
end
