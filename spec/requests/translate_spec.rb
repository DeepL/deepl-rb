# Copyright 2018 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::Translate do
  subject(:translate) { described_class.new(api, text, source_lang, target_lang, options) }

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:tags_str) { 'p,strong,span' }
  let(:tags_array) { %w[p strong span] }

  let(:api) { build_deepl_api }
  let(:text) { 'Sample text' }
  let(:source_lang) { 'EN' }
  let(:target_lang) { 'ES' }
  let(:options) { {} }

  describe '#initialize' do
    context 'when building a request' do
      it 'creates a request object' do
        expect(translate).to be_a(described_class)
      end
    end

    context 'when using `splitting_tags` options' do
      it 'works with a nil values' do
        request = described_class.new(api, nil, nil, nil, splitting_tags: nil)
        expect(request.options[:splitting_tags]).to be_nil
      end

      it 'works with a blank list' do
        request = described_class.new(api, nil, nil, nil, splitting_tags: '')
        expect(request.options[:splitting_tags]).to eq([])
      end

      it 'works with a comma-separated list and converts strings to an array' do
        request = described_class.new(api, nil, nil, nil, splitting_tags: tags_str)
        expect(request.options[:splitting_tags]).to eq(tags_array)
      end

      it 'works with an array of tags and leaves it as is' do
        request = described_class.new(api, nil, nil, nil, splitting_tags: tags_array)
        expect(request.options[:splitting_tags]).to eq(tags_array)
      end
    end

    context 'when using `non_splitting_tags` options' do
      it 'works with a nil values' do
        request = described_class.new(api, nil, nil, nil, non_splitting_tags: nil)
        expect(request.options[:non_splitting_tags]).to be_nil
      end

      it 'works with a blank list' do
        request = described_class.new(api, nil, nil, nil, non_splitting_tags: '')
        expect(request.options[:non_splitting_tags]).to eq([])
      end

      it 'works with a comma-separated list and converts strings to an array' do
        request = described_class.new(api, nil, nil, nil, non_splitting_tags: tags_str)
        expect(request.options[:non_splitting_tags]).to eq(tags_array)
      end

      it 'works with an array and leaves it as it is' do
        request = described_class.new(api, nil, nil, nil, non_splitting_tags: tags_array)
        expect(request.options[:non_splitting_tags]).to eq(tags_array)
      end
    end

    context 'when using `ignore_tags` options' do
      it 'works with a nil values' do
        request = described_class.new(api, nil, nil, nil, ignore_tags: nil)
        expect(request.options[:ignore_tags]).to be_nil
      end

      it 'works with a blank list' do
        request = described_class.new(api, nil, nil, nil, ignore_tags: '')
        expect(request.options[:ignore_tags]).to eq([])
      end

      it 'works with a comma-separated list and converts a string to an array' do
        request = described_class.new(api, nil, nil, nil, ignore_tags: tags_str)
        expect(request.options[:ignore_tags]).to eq(tags_array)
      end

      it 'works with an array and leaves it as it is' do
        request = described_class.new(api, nil, nil, nil, ignore_tags: tags_array)
        expect(request.options[:ignore_tags]).to eq(tags_array)
      end
    end

    context 'when using `split_sentences` options' do
      it 'converts `true` to `1`' do
        request = described_class.new(api, nil, nil, nil, split_sentences: true)
        expect(request.options[:split_sentences]).to eq('1')
      end

      it 'converts `false` to `0`' do
        request = described_class.new(api, nil, nil, nil, split_sentences: false)
        expect(request.options[:split_sentences]).to eq('0')
      end

      it 'leaves `0` as is' do
        request = described_class.new(api, nil, nil, nil, split_sentences: '0')
        expect(request.options[:split_sentences]).to eq('0')
      end

      it 'leaves `nonewlines` as is' do
        request = described_class.new(api, nil, nil, nil, split_sentences: 'nonewlines')
        expect(request.options[:split_sentences]).to eq('nonewlines')
      end

      it 'leaves `1` as is' do
        request = described_class.new(api, nil, nil, nil, split_sentences: '1')
        expect(request.options[:split_sentences]).to eq('1')
      end

      it 'works with provided constants' do
        request = described_class.new(
          api,
          nil,
          nil,
          nil,
          split_sentences: DeepL::Constants::SplitSentences::SPLIT_ON_PUNCTUATION_AND_NEWLINES
        )
        expect(request.options[:split_sentences]).to eq('1')
      end
    end

    context 'when using `preserve_formatting` options' do
      it 'leaves `true` as is' do
        request = described_class.new(api, nil, nil, nil, preserve_formatting: true)
        expect(request.options[:preserve_formatting]).to be(true)
      end

      it 'leaves `false` as is' do
        request = described_class.new(api, nil, nil, nil, preserve_formatting: false)
        expect(request.options[:preserve_formatting]).to be(false)
      end

      it 'converts `0` to `false`' do
        request = described_class.new(api, nil, nil, nil, preserve_formatting: '0')
        expect(request.options[:preserve_formatting]).to be(false)
      end

      it 'converts `1` to `true`' do
        request = described_class.new(api, nil, nil, nil, preserve_formatting: '1')
        expect(request.options[:preserve_formatting]).to be(true)
      end
    end

    context 'when using `outline_detection` options' do
      it 'leaves `true` as is' do
        request = described_class.new(api, nil, nil, nil, outline_detection: true)
        expect(request.options[:outline_detection]).to be(true)
      end

      it 'leaves `false` as is' do
        request = described_class.new(api, nil, nil, nil, outline_detection: false)
        expect(request.options[:outline_detection]).to be(false)
      end

      it 'converts `0` to `false`' do
        request = described_class.new(api, nil, nil, nil, outline_detection: '0')
        expect(request.options[:outline_detection]).to be(false)
      end

      it 'converts `1` to `true`' do
        request = described_class.new(api, nil, nil, nil, outline_detection: '1')
        expect(request.options[:outline_detection]).to be(true)
      end
    end

    context 'when using `glossary_id` options' do
      it 'works with a nil values' do
        request = described_class.new(api, nil, nil, nil, glossary_id: nil)
        expect(request.options[:glossary_id]).to be_nil
      end

      it 'works with a string' do
        request = described_class.new(api, nil, nil, nil, glossary_id: 'sample_id')
        expect(request.options[:glossary_id]).to eq('sample_id')
      end
    end

    context 'when using `glossary_ids` options' do
      it 'works with a nil value' do
        request = described_class.new(api, nil, nil, nil, glossary_ids: nil)
        expect(request.options[:glossary_ids]).to be_nil
      end

      it 'works with an array of strings' do
        request = described_class.new(api, nil, nil, nil, glossary_ids: %w[id1 id2])
        expect(request.options[:glossary_ids]).to eq(%w[id1 id2])
      end
    end

    context 'when building the `glossary_ids` request parameter' do
      def glossary_ids_param(source_lang, options)
        described_class.new(api, text, source_lang, target_lang, options)
                       .send(:build_glossary_ids_param, source_lang)
      end

      it 'returns nil when `glossary_ids` is not provided' do
        expect(glossary_ids_param('EN', {})).to be_nil
      end

      it 'returns nil when `glossary_ids` is nil' do
        expect(glossary_ids_param('EN', { glossary_ids: nil })).to be_nil
      end

      it 'returns nil when `glossary_ids` is an empty array' do
        expect(glossary_ids_param('EN', { glossary_ids: [] })).to be_nil
      end

      it 'resolves an array of IDs to an array of strings' do
        expect(glossary_ids_param('EN', { glossary_ids: %w[id1 id2 id3] })).to eq(%w[id1 id2 id3])
      end

      it 'resolves glossary objects to their IDs' do
        glossary = DeepL::Resources::Glossary.new({ 'glossary_id' => 'obj_id' }, nil, nil)
        expect(glossary_ids_param('EN', { glossary_ids: [glossary, 'id2'] })).to eq(%w[obj_id id2])
      end

      it 'raises when `source_lang` is not set' do
        expect { glossary_ids_param(nil, { glossary_ids: %w[id1] }) }
          .to raise_error(ArgumentError, /requires `source_lang`/)
      end

      it 'raises when combined with the singular `glossary_id` option' do
        expect { glossary_ids_param('EN', { glossary_id: 'single', glossary_ids: %w[id1] }) }
          .to raise_error(ArgumentError, /cannot be used together with the `glossary_id`/)
      end

      it 'raises when more than 5 IDs are provided' do
        expect { glossary_ids_param('EN', { glossary_ids: %w[id1 id2 id3 id4 id5 id6] }) }
          .to raise_error(ArgumentError, /maximum of 5 glossary IDs/)
      end
    end

    context 'when using `formality` options' do
      it 'works with a nil values' do
        request = described_class.new(api, nil, nil, nil, formality: nil)
        expect(request.options[:formality]).to be_nil
      end

      it 'works with a string' do
        request = described_class.new(api, nil, nil, nil, formality: 'more')
        expect(request.options[:formality]).to eq('more')
      end

      it 'works with provided constants' do
        request = described_class.new(api, nil, nil, nil,
                                      formality: DeepL::Constants::Formality::MORE)
        expect(request.options[:formality]).to eq('more')
      end
    end

    context 'when using `tag_handling_version` options' do
      it 'works with a nil value' do
        request = described_class.new(api, nil, nil, nil, tag_handling_version: nil)
        expect(request.options[:tag_handling_version]).to be_nil
      end

      it 'works with v1' do
        request = described_class.new(api, nil, nil, nil, tag_handling_version: 'v1')
        expect(request.options[:tag_handling_version]).to eq('v1')
      end

      it 'works with v2' do
        request = described_class.new(api, nil, nil, nil, tag_handling_version: 'v2')
        expect(request.options[:tag_handling_version]).to eq('v2')
      end
    end

    context 'when using `model_type` options' do
      it 'works with a nil value' do
        request = described_class.new(api, nil, nil, nil, model_type: nil)
        expect(request.options[:model_type]).to be_nil
      end

      it 'works with a string' do
        request = described_class.new(api, nil, nil, nil, model_type: 'latency_optimized')
        expect(request.options[:model_type]).to eq('latency_optimized')
      end

      it 'works with provided constants' do
        request = described_class.new(api, nil, nil, nil,
                                      model_type: DeepL::Constants::ModelType::LATENCY_OPTIMIZED)
        expect(request.options[:model_type]).to eq('latency_optimized')
      end
    end

    context 'when using `custom_instructions` options' do
      it 'works with a nil value' do
        request = described_class.new(api, nil, nil, nil, custom_instructions: nil)
        expect(request.options[:custom_instructions]).to be_nil
      end

      it 'works with an array of strings' do
        instructions = ['Use informal language', 'Be concise']
        request = described_class.new(api, nil, nil, nil, custom_instructions: instructions)
        expect(request.options[:custom_instructions]).to eq(instructions)
      end

      it 'works with a single string' do
        request = described_class.new(api, nil, nil, nil, custom_instructions: ['Be concise'])
        expect(request.options[:custom_instructions]).to eq(['Be concise'])
      end

      it 'works with a single string and converts it to an array' do
        instructions = 'Use informal language,Be concise'
        request = described_class.new(api, nil, nil, nil, custom_instructions: instructions)
        expect(request.options[:custom_instructions]).to eq(['Use informal language', 'Be concise'])
      end
    end

    context 'when passing additional headers' do
      it 'merges the headers into the request headers' do
        request = described_class.new(api, nil, nil, nil, {},
                                      { 'X-DeepL-Reporting-Tag' => 'my-tag' })
        expect(request.send(:headers)).to include('X-DeepL-Reporting-Tag' => 'my-tag')
      end

      it 'defaults to no additional headers' do
        request = described_class.new(api, nil, nil, nil)
        expect(request.send(:headers).keys).to contain_exactly('Authorization', 'User-Agent')
      end
    end
  end
end
