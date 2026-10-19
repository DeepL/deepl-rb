# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL.style_rules' do
  it 'sends the style rule requests: create, get, list, rename, configure, instructions, delete' do
    style_rules = DeepL.style_rules
    name = unique_name('style-rule')
    rules = { dates_and_times: { calendar_era: 'use_bc_and_ad' } }

    rule = style_rules.create(name, 'en', configured_rules: rules,
                                          custom_instructions: [{ label: 'Init',
                                                                  prompt: 'Be formal',
                                                                  source_language: 'de' }])
    style_id = rule.style_id
    begin
      expect([rule.name, rule.language, rule.creation_time.class]).to eq([name, 'en', Time])

      fetched = style_rules.find(style_id)
      expect([fetched.style_id, fetched.name]).to eq([style_id, name])
      expect(found_on_any_page?(style_id) do |page|
        style_rules.list(page: page, page_size: 25, detailed: true).map(&:style_id)
      end).to be(true)

      expect(style_rules.update_name(style_id, "#{name}-renamed").name).to eq("#{name}-renamed")
      expect(style_rules.update_configured_rules(style_id, rules).style_id).to eq(style_id)

      instruction = style_rules.create_custom_instruction(style_id, 'Label', 'Prompt', 'de')
      expect([instruction.id.class, instruction.label]).to eq([String, 'Label'])
      found = style_rules.find_custom_instruction(style_id, instruction.id)
      expect(found.prompt).to eq('Prompt')
      updated = style_rules.update_custom_instruction(style_id, instruction.id, 'New Label',
                                                      'New Prompt', 'en')
      expect(updated.label).to eq('New Label')
      style_rules.destroy_custom_instruction(style_id, instruction.id)
    ensure
      delete_quietly { style_rules.destroy(style_id) }
    end
  end
end
