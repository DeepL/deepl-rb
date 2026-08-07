# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Requests::Document::Upload do
  subject(:upload) do
    described_class.new(api, input_file_path, source_lang, target_lang, filename, options)
  end

  around do |tests|
    tmp_env = replace_env_preserving_deepl_vars_except_mock_server
    tests.call
    ENV.replace(tmp_env)
  end

  let(:api) { build_deepl_api }
  let(:input_file_path) { '/tmp/example.txt' }
  let(:source_lang) { 'EN' }
  let(:target_lang) { 'DE' }
  let(:filename) { 'example.txt' }
  let(:options) { {} }
  let(:input_file) { instance_double(File) }

  # Builds the multipart form data without performing any network or filesystem IO.
  def form_data
    upload.send(:build_base_form_data, input_file)
  end

  def form_value(form, key)
    field = form.find { |name, _| name == key }
    field&.last
  end

  describe '#initialize' do
    it 'creates a request object' do
      expect(upload).to be_a(described_class)
    end
  end

  describe 'building the upload form data' do
    context 'when using the `style_rule` option' do
      it 'does not append a `style_id` field when not provided' do
        expect(form_value(form_data, 'style_id')).to be_nil
      end

      it 'appends a `style_id` field from a style rule ID string' do
        options[:style_rule] = 'style-123'
        expect(form_value(form_data, 'style_id')).to eq('style-123')
      end

      it 'appends a `style_id` field from a StyleRule object' do
        options[:style_rule] =
          DeepL::Resources::StyleRule.new({ 'style_id' => 'style-obj' }, nil, nil)
        expect(form_value(form_data, 'style_id')).to eq('style-obj')
      end
    end

    context 'when using the `translation_memory` option' do
      it 'does not append a `translation_memory_id` field when not provided' do
        expect(form_value(form_data, 'translation_memory_id')).to be_nil
      end

      it 'appends a `translation_memory_id` field from a translation memory ID string' do
        options[:translation_memory] = 'tm-123'
        expect(form_value(form_data, 'translation_memory_id')).to eq('tm-123')
      end

      it 'appends a `translation_memory_id` field from a TranslationMemory object' do
        options[:translation_memory] =
          DeepL::Resources::TranslationMemory.new({ 'translation_memory_id' => 'tm-obj' }, nil, nil)
        expect(form_value(form_data, 'translation_memory_id')).to eq('tm-obj')
      end

      it 'appends a `translation_memory_threshold` field serialized to a string' do
        options[:translation_memory] = 'tm-123'
        options[:translation_memory_threshold] = 80
        form = form_data
        expect(form_value(form, 'translation_memory_id')).to eq('tm-123')
        expect(form_value(form, 'translation_memory_threshold')).to eq('80')
      end

      it 'does not append a `translation_memory_threshold` field when not provided' do
        options[:translation_memory] = 'tm-123'
        expect(form_value(form_data, 'translation_memory_threshold')).to be_nil
      end
    end

    context 'when using the `glossary_ids` option' do
      it 'does not append a `glossary_ids` field when not provided' do
        expect(form_value(form_data, 'glossary_ids')).to be_nil
      end

      it 'appends a comma-separated `glossary_ids` field from an array of IDs' do
        options[:glossary_ids] = %w[gid1 gid2 gid3]
        expect(form_value(form_data, 'glossary_ids')).to eq('gid1,gid2,gid3')
      end

      it 'appends `glossary_ids` from Glossary objects using their IDs' do
        options[:glossary_ids] = [
          DeepL::Resources::Glossary.new({ 'glossary_id' => 'gid-obj' }, nil, nil),
          'gid-str'
        ]
        expect(form_value(form_data, 'glossary_ids')).to eq('gid-obj,gid-str')
      end

      it 'raises when combined with the singular `glossary_id` option' do
        options[:glossary_id] = 'single'
        options[:glossary_ids] = %w[gid1]
        expect { form_data }.to raise_error(ArgumentError, /cannot be used together/)
      end

      it 'raises when more than 5 glossary IDs are provided' do
        options[:glossary_ids] = %w[a b c d e f]
        expect { form_data }.to raise_error(ArgumentError, /maximum of 5 glossary IDs/)
      end

      context 'when `source_lang` is not set' do
        let(:source_lang) { nil }

        it 'raises because `glossary_ids` requires `source_lang`' do
          options[:glossary_ids] = %w[gid1]
          expect { form_data }.to raise_error(ArgumentError, /requires `source_lang`/)
        end
      end
    end
  end
end
