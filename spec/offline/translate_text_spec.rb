# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'DeepL.translate' do
  let(:translation_reply) { reply(translations: [{ text: 'Hallo' }]) }

  def expect_body(body)
    stub_request(:post, url('/v2/translate')).with(body: body, headers: json_headers)
                                             .to_return(translation_reply)
  end

  it 'sends the text with a null source language for auto-detection' do
    expect_body(text: ['Hello'], source_lang: nil, target_lang: 'DE')
    DeepL.translate('Hello', nil, 'DE')
  end

  it 'sends the source language and several texts' do
    stub_request(:post, url('/v2/translate'))
      .with(body: { text: %w[Hello Bye], source_lang: 'EN', target_lang: 'DE' })
      .to_return(reply(translations: [{ text: 'Hallo' }, { text: 'Tschüss' }]))

    expect(DeepL.translate(%w[Hello Bye], 'EN', 'DE').map(&:class))
      .to eq([DeepL::Resources::Text] * 2)
  end

  it 'sends the additional headers' do
    stub_request(:post, url('/v2/translate'))
      .with(headers: json_headers.merge('X-DeepL-Reporting-Tag' => 'tag'))
      .to_return(translation_reply)

    DeepL.translate('Hello', 'EN', 'DE', {}, { 'X-DeepL-Reporting-Tag' => 'tag' })
  end

  it 'sends options given with string keys' do
    expect_body(text: ['Hello'], source_lang: 'EN', target_lang: 'DE', split_sentences: '1',
                formality: 'less')
    DeepL.translate('Hello', 'EN', 'DE', 'formality' => 'less', 'split_sentences' => true)
  end

  describe 'options passed through unchanged' do
    {
      formality: 'prefer_more',
      tag_handling: 'xml',
      tag_handling_version: 'v2',
      context: 'A greeting',
      model_type: 'latency_optimized',
      glossary_id: 'g-1',
      show_billed_characters: true
    }.each do |option, value|
      it "sends #{option}" do
        expect_body({ text: ['Hello'], source_lang: 'EN', target_lang: 'DE', option => value })
        DeepL.translate('Hello', 'EN', 'DE', option => value)
      end
    end
  end

  describe 'option conversions' do
    { true => '1', false => '0', 'nonewlines' => 'nonewlines' }.each do |value, sent|
      it "sends split_sentences #{value.inspect} as #{sent.inspect}" do
        expect_body(text: ['a'], source_lang: nil, target_lang: 'DE', split_sentences: sent)
        DeepL.translate('a', nil, 'DE', split_sentences: value)
      end
    end

    it 'converts split_sentences false given with a string key' do
      expect_body(text: ['a'], source_lang: nil, target_lang: 'DE', split_sentences: '0')
      DeepL.translate('a', nil, 'DE', 'split_sentences' => false)
    end

    { '1' => true, '0' => false, true => true }.each do |value, sent|
      %i[preserve_formatting outline_detection].each do |option|
        it "sends #{option} #{value.inspect} as #{sent.inspect}" do
          expect_body({ text: ['a'], source_lang: nil, target_lang: 'DE', option => sent })
          DeepL.translate('a', nil, 'DE', option => value)
        end
      end
    end

    %i[splitting_tags non_splitting_tags ignore_tags custom_instructions].each do |option|
      it "sends a comma separated #{option} string as an array" do
        expect_body({ text: ['a'], source_lang: nil, target_lang: 'DE', option => %w[x y] })
        DeepL.translate('a', nil, 'DE', option => 'x,y')
      end

      it "sends a #{option} array unchanged" do
        expect_body({ text: ['a'], source_lang: nil, target_lang: 'DE', option => %w[x y] })
        DeepL.translate('a', nil, 'DE', option => %w[x y])
      end
    end
  end

  describe 'style rules and translation memories' do
    let(:base) { { text: ['a'], source_lang: 'EN', target_lang: 'DE' } }

    it 'sends a style rule ID as style_id' do
      expect_body(base.merge(style_id: 's-1'))
      DeepL.translate('a', 'EN', 'DE', style_rule: 's-1')
    end

    it 'sends the ID of a style rule object as style_id' do
      expect_body(base.merge(style_id: 's-2'))
      rule = DeepL::Resources::StyleRule.new({ 'style_id' => 's-2' }, nil, nil)
      DeepL.translate('a', 'EN', 'DE', style_rule: rule)
    end

    it 'sends no style_id when the style rule is nil' do
      expect_body(base)
      DeepL.translate('a', 'EN', 'DE', style_rule: nil)
    end

    it 'sends a style profile ID as style_profile_id' do
      expect_body(base.merge(style_profile_id: 'sp-1'))
      DeepL.translate('a', 'EN', 'DE', style_profile: 'sp-1')
    end

    it 'sends the ID of a style profile object as style_profile_id' do
      expect_body(base.merge(style_profile_id: 'sp-2'))
      profile = DeepL::Resources::StyleProfile.new({ 'style_profile_id' => 'sp-2' }, nil, nil)
      DeepL.translate('a', 'EN', 'DE', style_profile: profile)
    end

    it 'sends no style_profile_id when the option is not set' do
      expect_body(base)
      DeepL.translate('a', 'EN', 'DE')
    end

    it 'sends no style_profile_id when the option is nil' do
      expect_body(base)
      DeepL.translate('a', 'EN', 'DE', style_profile: nil)
    end

    it 'sends a translation memory ID with its threshold' do
      expect_body(base.merge(translation_memory_id: 'tm-1', translation_memory_threshold: 80))
      DeepL.translate('a', 'EN', 'DE', translation_memory: 'tm-1',
                                       translation_memory_threshold: 80)
    end

    it 'sends the ID of a translation memory object' do
      memory = DeepL::Resources::TranslationMemory.new({ 'translation_memory_id' => 'tm-2' },
                                                       nil, nil)
      expect_body(base.merge(translation_memory_id: 'tm-2'))
      DeepL.translate('a', 'EN', 'DE', translation_memory: memory)
    end
  end

  describe 'glossary_ids' do
    let(:base) { { text: ['a'], source_lang: 'EN', target_lang: 'DE' } }

    it 'sends glossary IDs, glossary objects and multilingual glossary objects as IDs' do
      glossary = DeepL::Resources::Glossary.new({ 'glossary_id' => 'g-2' }, nil, nil)
      multilingual = DeepL::Resources::MultilingualGlossary.new({ 'glossary_id' => 'g-3' }, nil,
                                                                nil)
      expect_body(base.merge(glossary_ids: %w[g-1 g-2 g-3]))

      DeepL.translate('a', 'EN', 'DE', glossary_ids: ['g-1', glossary, multilingual])
    end

    it 'raises ArgumentError without a source language' do
      expect { DeepL.translate('a', nil, 'DE', glossary_ids: ['g-1']) }
        .to raise_error(ArgumentError, /requires `source_lang`/)
    end

    it 'raises ArgumentError together with glossary_id' do
      expect { DeepL.translate('a', 'EN', 'DE', glossary_ids: ['g-1'], glossary_id: 'g-2') }
        .to raise_error(ArgumentError, /cannot be used together/)
    end

    it 'raises ArgumentError for more than 5 glossaries' do
      expect { DeepL.translate('a', 'EN', 'DE', glossary_ids: %w[1 2 3 4 5 6]) }
        .to raise_error(ArgumentError, /maximum of 5/)
    end
  end

  describe 'extra_body_parameters' do
    it 'keeps the type of each value' do
      extra = { flag: true, off: false, count: 42, label: 'x', list: [1, 'a'], nested: { a: 1 } }
      expect_body({ text: ['a'], source_lang: nil, target_lang: 'DE' }.merge(extra))

      DeepL.translate('a', nil, 'DE', extra_body_parameters: extra)
    end

    it 'adds new parameters and overrides built-in ones' do
      expect_body(text: ['a'], source_lang: nil, target_lang: 'FR', beta_feature: 'on')
      DeepL.translate('a', nil, 'DE', extra_body_parameters: { target_lang: 'FR',
                                                               beta_feature: 'on' })
    end
  end
end
