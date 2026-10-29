# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'style rules' do
  describe DeepL::StyleRuleApi do
    let(:style_rules) { DeepL.style_rules }
    let(:style_json) do
      { style_id: 's-1', name: 'house style', language: 'en', version: 3,
        creation_time: '2026-01-02T03:04:05Z', updated_time: '2026-02-03T04:05:06Z',
        configured_rules: { numbers: { number_format: 'dot' } },
        custom_instructions: [{ id: 'i-1', label: 'Tone', prompt: 'Be brief',
                                source_language: 'en' }] }
    end
    let(:instruction_json) { { id: 'i-1', label: 'Tone', prompt: 'Be brief' } }

    describe '#list' do
      it 'sends a GET without a query by default' do
        stub_request(:get, url('/v3/style_rules')).with(headers: json_headers)
                                                  .to_return(reply(style_rules: [style_json]))

        style_rules.list
      end

      it 'sends page, page_size and detailed in the query' do
        stub_request(:get, url('/v3/style_rules?page=2&page_size=5&detailed=true'))
          .to_return(reply(style_rules: []))

        style_rules.list(page: 2, page_size: 5, detailed: true)
      end

      it 'parses the timestamps of the style rules' do
        stub_request(:get, url('/v3/style_rules')).to_return(reply(style_rules: [style_json]))

        rule = style_rules.list.first

        expect([rule.creation_time, rule.updated_time])
          .to eq([Time.utc(2026, 1, 2, 3, 4, 5), Time.utc(2026, 2, 3, 4, 5, 6)])
      end

      it 'raises a DeepL error for a malformed timestamp' do
        stub_request(:get, url('/v3/style_rules'))
          .to_return(reply(style_rules: [style_json.merge(creation_time: 'not a time')]))

        expect { style_rules.list }.to raise_error(DeepL::Exceptions::Error, /invalid time/)
      end
    end

    describe '#create' do
      it 'sends the name and language' do
        stub_request(:post, url('/v3/style_rules'))
          .with(body: { name: 'house style', language: 'en' }, headers: json_headers)
          .to_return(reply(style_json, 201))

        style_rules.create('house style', 'en')
      end

      it 'sends the configured rules and the custom instructions' do
        rules = { numbers: { number_format: 'dot' } }
        instructions = [{ label: 'Tone', prompt: 'Be brief' }]
        stub_request(:post, url('/v3/style_rules'))
          .with(body: { name: 'n', language: 'en', configured_rules: rules,
                        custom_instructions: instructions })
          .to_return(reply(style_json, 201))

        style_rules.create('n', 'en', configured_rules: rules, custom_instructions: instructions)
      end

      it 'keeps the configured rules and custom instructions in a reused options hash' do
        options = { configured_rules: { numbers: { number_format: 'dot' } },
                    custom_instructions: [{ label: 'Tone', prompt: 'Be brief' }] }
        stub_request(:post, url('/v3/style_rules'))
          .with(body: { name: 'n', language: 'en' }.merge(options))
          .to_return(reply(style_json, 201)).times(2)

        2.times { style_rules.create('n', 'en', options) }
      end

      it 'parses the configured rules, defaulting missing rules to an empty hash' do
        stub_request(:post, url('/v3/style_rules')).to_return(reply(style_json, 201))

        rule = style_rules.create('n', 'en')

        expect([rule.configured_rules.vocabulary, rule.custom_instructions.map(&:class)])
          .to eq([{}, [DeepL::Resources::CustomInstruction]])
      end
    end

    describe '#find' do
      it 'sends a GET with an empty JSON body' do
        stub_request(:get, url('/v3/style_rules/s-1')).with(body: '{}', headers: json_headers)
                                                      .to_return(reply(style_json))

        style_rules.find('s-1')
      end
    end

    describe 'IDs in the path' do
      it 'URL-encodes the style rule ID and the custom instruction ID' do
        stub_request(:get, url('/v3/style_rules/a%2Fb%20c')).to_return(reply(style_json))
        stub_request(:delete, url('/v3/style_rules/a%2Fb%20c/custom_instructions/i%2F1%20x'))
          .to_return(status: 204)

        style_rules.find('a/b c')
        style_rules.destroy_custom_instruction('a/b c', 'i/1 x')
      end
    end

    describe 'resource objects' do
      let(:rule) { DeepL::Resources::StyleRule.new({ 'style_id' => 's-1', 'name' => 'n' }, nil, nil) }
      let(:instruction) { DeepL::Resources::CustomInstruction.new('id' => 'i-1') }

      it 'sends the ID of a StyleRule object' do
        stub_request(:get, url('/v3/style_rules/s-1')).to_return(reply(style_json))
        stub_request(:patch, url('/v3/style_rules/s-1')).to_return(reply(style_json))
        stub_request(:put, url('/v3/style_rules/s-1/configured_rules')).to_return(reply(style_json))
        stub_request(:delete, url('/v3/style_rules/s-1')).to_return(status: 204)

        style_rules.find(rule)
        style_rules.update_name(rule, 'new')
        style_rules.update_configured_rules(rule, {})
        style_rules.destroy(rule)
      end

      it 'sends the IDs of StyleRule and CustomInstruction objects' do
        path = url('/v3/style_rules/s-1/custom_instructions/i-1')
        stub_request(:post, url('/v3/style_rules/s-1/custom_instructions'))
          .to_return(reply(instruction_json, 201))
        stub_request(:get, path).to_return(reply(instruction_json))
        stub_request(:put, path).to_return(reply(instruction_json))
        stub_request(:delete, path).to_return(status: 204)

        style_rules.create_custom_instruction(rule, 'Tone', 'Be brief')
        style_rules.find_custom_instruction(rule, instruction)
        style_rules.update_custom_instruction(rule, instruction, 'New', 'Be long')
        style_rules.destroy_custom_instruction(rule, instruction)
      end
    end

    describe '#update_name' do
      it 'sends a PATCH with the name' do
        stub_request(:patch, url('/v3/style_rules/s-1'))
          .with(body: { name: 'new' }, headers: json_headers).to_return(reply(style_json))

        style_rules.update_name('s-1', 'new')
      end
    end

    describe '#update_configured_rules' do
      it 'sends the configured rules as the PUT body' do
        rules = { numbers: { number_format: 'comma' } }
        stub_request(:put, url('/v3/style_rules/s-1/configured_rules'))
          .with(body: rules, headers: json_headers).to_return(reply(style_json))

        style_rules.update_configured_rules('s-1', rules)
      end
    end

    describe '#destroy' do
      it 'sends a DELETE with an empty JSON body and returns the ID' do
        stub_request(:delete, url('/v3/style_rules/s-1')).with(body: '{}', headers: json_headers)
                                                         .to_return(status: 204)

        expect(style_rules.destroy('s-1')).to eq('s-1')
      end
    end

    describe 'custom instructions' do
      it 'sends the label and prompt on create, with the source language when given' do
        stub_request(:post, url('/v3/style_rules/s-1/custom_instructions'))
          .with(body: { label: 'Tone', prompt: 'Be brief' }, headers: json_headers)
          .to_return(reply(instruction_json, 201))
        stub_request(:post, url('/v3/style_rules/s-1/custom_instructions'))
          .with(body: { label: 'Tone', prompt: 'Be brief', source_language: 'de' })
          .to_return(reply(instruction_json.merge(source_language: 'de'), 201))

        style_rules.create_custom_instruction('s-1', 'Tone', 'Be brief')
        style_rules.create_custom_instruction('s-1', 'Tone', 'Be brief', 'de')
      end

      it 'sends a GET on find' do
        stub_request(:get, url('/v3/style_rules/s-1/custom_instructions/i-1'))
          .with(body: '{}', headers: json_headers).to_return(reply(instruction_json))

        style_rules.find_custom_instruction('s-1', 'i-1')
      end

      it 'sends the label and prompt on update, with the source language when given' do
        stub_request(:put, url('/v3/style_rules/s-1/custom_instructions/i-1'))
          .with(body: { label: 'New', prompt: 'Be long' }, headers: json_headers)
          .to_return(reply(instruction_json))
        stub_request(:put, url('/v3/style_rules/s-1/custom_instructions/i-1'))
          .with(body: { label: 'New', prompt: 'Be long', source_language: 'de' })
          .to_return(reply(instruction_json))

        style_rules.update_custom_instruction('s-1', 'i-1', 'New', 'Be long')
        style_rules.update_custom_instruction('s-1', 'i-1', 'New', 'Be long', 'de')
      end

      it 'sends a DELETE on destroy and returns the instruction ID' do
        stub_request(:delete, url('/v3/style_rules/s-1/custom_instructions/i-1'))
          .with(body: '{}', headers: json_headers).to_return(status: 204)

        expect(style_rules.destroy_custom_instruction('s-1', 'i-1')).to eq('i-1')
      end
    end
  end

  # The client has its own key and server, different from the module configuration, so a request
  # that falls back to module state hits no stub.
  describe 'DeepL::Client' do
    let(:client) { DeepL::Client.new('client-key', server_url: 'https://client.example.test') }
    let(:style_json) { { style_id: 's-1', name: 'house style', language: 'en', version: 1 } }
    let(:instruction_json) { { id: 'i-1', label: 'Tone', prompt: 'Be brief' } }
    let(:rule) { DeepL::Resources::StyleRule.new({ 'style_id' => 's-1', 'name' => 'n' }, nil, nil) }
    let(:instruction) { DeepL::Resources::CustomInstruction.new('id' => 'i-1') }

    def url(path)
      "https://client.example.test#{path}"
    end

    def json_headers
      { 'Authorization' => 'DeepL-Auth-Key client-key', 'Content-Type' => 'application/json' }
    end

    describe '#get_all_style_rules' do
      it 'sends no query by default' do
        stub_request(:get, url('/v3/style_rules')).with(headers: json_headers)
                                                  .to_return(reply(style_rules: [style_json]))

        expect(client.get_all_style_rules.map(&:style_id)).to eq(['s-1'])
      end

      it 'sends page, page_size and detailed in the query' do
        stub_request(:get, url('/v3/style_rules?page=1&page_size=5&detailed=false'))
          .to_return(reply(style_rules: []))

        client.get_all_style_rules(page: 1, page_size: 5, detailed: false)
      end
    end

    describe '#create_style_rule' do
      it 'sends the name and language only by default' do
        stub_request(:post, url('/v3/style_rules'))
          .with(body: { name: 'n', language: 'en' }, headers: json_headers)
          .to_return(reply(style_json, 201))

        expect(client.create_style_rule('n', 'en').style_id).to eq('s-1')
      end

      it 'sends the configured rules, custom instructions and extra body parameters' do
        rules = { numbers: { number_format: 'dot' } }
        instructions = [{ label: 'Tone', prompt: 'Be brief', source_language: 'en' }]
        stub_request(:post, url('/v3/style_rules'))
          .with(body: { name: 'n', language: 'en', configured_rules: rules,
                        custom_instructions: instructions, extra: 'x' })
          .to_return(reply(style_json, 201))

        client.create_style_rule('n', 'en', configured_rules: rules,
                                            custom_instructions: instructions,
                                            extra_body_parameters: { extra: 'x' })
      end
    end

    describe 'per-list operations' do
      it 'sends get, rename, configured rules update and delete for an ID or a StyleRule' do
        stub_request(:get, url('/v3/style_rules/s-1')).to_return(reply(style_json))
        stub_request(:patch, url('/v3/style_rules/s-1')).with(body: { name: 'new' })
                                                        .to_return(reply(style_json))
        stub_request(:put, url('/v3/style_rules/s-1/configured_rules'))
          .with(body: { numbers: { number_format: 'comma' } }).to_return(reply(style_json))
        stub_request(:delete, url('/v3/style_rules/s-1')).to_return(status: 204)

        client.get_style_rule(rule)
        client.update_style_rule_name('s-1', 'new')
        client.update_style_rule_configured_rules(rule, { numbers: { number_format: 'comma' } })
        expect(client.delete_style_rule(rule)).to be_nil
      end
    end

    describe 'custom instructions' do
      let(:path) { url('/v3/style_rules/s-1/custom_instructions/i-1') }

      it 'sends create with the source language only when given' do
        stub_request(:post, url('/v3/style_rules/s-1/custom_instructions'))
          .with(body: { label: 'Tone', prompt: 'Be brief' }).to_return(reply(instruction_json, 201))
        stub_request(:post, url('/v3/style_rules/s-1/custom_instructions'))
          .with(body: { label: 'Tone', prompt: 'Be brief', source_language: 'de' })
          .to_return(reply(instruction_json, 201))

        client.create_style_rule_custom_instruction(rule, 'Tone', 'Be brief')
        client.create_style_rule_custom_instruction('s-1', 'Tone', 'Be brief',
                                                    source_language: 'de')
      end

      it 'sends get, update and delete for an ID or a CustomInstruction' do
        stub_request(:get, path).with(headers: json_headers).to_return(reply(instruction_json))
        stub_request(:put, path)
          .with(body: { label: 'New', prompt: 'Be long', source_language: 'de' })
          .to_return(reply(instruction_json))
        stub_request(:delete, path).to_return(status: 204)

        expect(client.get_style_rule_custom_instruction(rule, instruction).id).to eq('i-1')
        client.update_style_rule_custom_instruction('s-1', 'i-1', 'New', 'Be long',
                                                    source_language: 'de')
        expect(client.delete_style_rule_custom_instruction(rule, instruction)).to be_nil
      end
    end
  end
end
