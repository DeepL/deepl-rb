# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'real_api_helper'

describe 'DeepL::Client style rules' do
  let(:client) do
    DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'), server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  end

  it 'sends the style rule requests: create, get, list, rename, configure, instructions, delete' do
    name = unique_name('style-rule')
    rules = { dates_and_times: { calendar_era: 'use_bc_and_ad' } }

    rule = client.create_style_rule(name, 'en', configured_rules: rules,
                                                custom_instructions: [{ label: 'Init',
                                                                        prompt: 'Be formal',
                                                                        source_language: 'de' }])
    begin
      expect([rule.name, rule.language, rule.creation_time.class]).to eq([name, 'en', Time])

      fetched = client.get_style_rule(rule.style_id)
      expect([fetched.style_id, fetched.name]).to eq([rule.style_id, name])
      expect(found_on_any_page?(rule.style_id) do |page|
        client.get_all_style_rules(page: page, page_size: 25, detailed: true).map(&:style_id)
      end).to be(true)

      expect(client.update_style_rule_name(rule, "#{name}-renamed").name).to eq("#{name}-renamed")
      expect(client.update_style_rule_configured_rules(rule, rules).style_id).to eq(rule.style_id)

      instruction = client.create_style_rule_custom_instruction(rule, 'Label', 'Prompt',
                                                                source_language: 'de')
      expect([instruction.id.class, instruction.label]).to eq([String, 'Label'])
      found = client.get_style_rule_custom_instruction(rule, instruction)
      expect(found.prompt).to eq('Prompt')
      updated = client.update_style_rule_custom_instruction(rule, instruction.id, 'New Label',
                                                            'New Prompt', source_language: 'en')
      expect(updated.label).to eq('New Label')
      expect(client.delete_style_rule_custom_instruction(rule, instruction)).to be_nil
    ensure
      delete_quietly { client.delete_style_rule(rule) }
    end
  end
end
