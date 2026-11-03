# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe 'unknown options' do
  include_context 'with a temporary directory'

  def expect_rejected(name)
    expect { yield api_client }.to raise_error(ArgumentError, /Unknown option `#{name}`/)
    expect(a_request(:any, //)).not_to have_been_made
  end

  it 'raises for a misspelled text translation option without sending a request' do
    expect_rejected('formalty') { |c| c.translate_text('a', 'EN', 'DE', formalty: 'less') }
  end

  it 'raises for the removed glossary_id text translation option' do
    expect_rejected('glossary_id') { |c| c.translate_text('a', 'EN', 'DE', glossary_id: 'g-1') }
  end

  it 'raises for an unknown document translation option without uploading' do
    input, = create_text_document(temp_dir)
    expect_rejected('glossary_id') do |c|
      c.translate_document_upload(input, 'EN', 'DE', glossary_id: 'g-1')
    end
    expect_rejected('formalty') do |c|
      c.translate_document(input, File.join(temp_dir, 'out.txt'), 'EN', 'DE', formalty: 'more')
    end
  end

  it 'raises for an unknown rephrase or correct option' do
    expect_rejected('context') { |c| c.rephrase_text('a', 'EN', context: 'x') }
    expect_rejected('formality') { |c| c.correct_text('a', 'EN', formality: 'less') }
  end

  it 'raises for an unknown glossary option' do
    expect_rejected('unknown') do |c|
      c.create_glossary('terms', 'EN', 'DE', { 'a' => 'b' }, unknown: 1)
    end
    expect_rejected('unknown') do |c|
      c.create_multilingual_glossary_from_csv('terms', 'EN', 'DE', "a,b\n", unknown: 1)
    end
  end

  it 'raises for an unknown spoken terms option' do
    expect_rejected('unknown') { |c| c.create_spoken_terms('terms', [], unknown: 1) }
  end

  it 'raises for an unknown style rule or style profile option' do
    expect_rejected('unknown') { |c| c.create_style_rule('rules', 'en', unknown: 1) }
    expect_rejected('unknown') { |c| c.create_style_profile('profile', unknown: 1) }
  end

  it 'raises for an unknown translation memory import option' do
    expect { api_client.create_translation_memory_import('tm.tmx', 10, unknown: 1) }
      .to raise_error(ArgumentError, /unknown keyword: :unknown/)
    expect(a_request(:any, //)).not_to have_been_made
  end

  it 'names every unknown option given with a string or symbol key' do
    expect { api_client.translate_text('a', 'EN', 'DE', 'a' => 1, b: 2) }
      .to raise_error(ArgumentError, /Unknown options `a`, `b`; use `extra_body_parameters`/)
  end
end
