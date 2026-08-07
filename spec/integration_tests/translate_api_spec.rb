# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe 'DeepL.translate' do # rubocop:disable RSpec/DescribeClass
  include_context 'with a live mock server'

  let(:text) { 'proton beam' }

  describe 'happy path' do
    it 'translates a single string into a Text resource' do
      result = DeepL.translate(text, 'EN', 'DE')

      expect(result).to be_a(DeepL::Resources::Text)
      expect(result.text).to be_a(String)
      expect(result.text).not_to be_empty
    end

    it 'translates an array of strings into an array of Text resources' do
      results = DeepL.translate(%w[Sample Word], 'EN', 'ES')

      expect(results).to be_an(Array)
      expect(results.size).to eq(2)
      expect(results).to all(be_a(DeepL::Resources::Text))
    end
  end

  describe 'options' do
    it 'accepts a formality setting' do
      result = DeepL.translate('How are you?', 'EN', 'DE', { formality: 'more' })

      expect(result).to be_a(DeepL::Resources::Text)
    end

    it 'translates with XML tag handling and ignored tags' do
      result = DeepL.translate('<p>Sample <code>x</code></p>', 'EN', 'ES',
                               { tag_handling: 'xml', ignore_tags: %w[code] })

      expect(result.text).to be_a(String)
      expect(result.text).not_to be_empty
    end

    it 'accepts a context option' do
      result = DeepL.translate('That is hot!', 'EN', 'ES', { context: 'about the weather' })

      expect(result).to be_a(DeepL::Resources::Text)
    end

    it 'accepts an empty context option' do
      result = DeepL.translate('That is hot!', 'EN', 'ES', { context: '' })

      expect(result).to be_a(DeepL::Resources::Text)
    end

    it 'translates an HTML document with split_sentences, outline_detection and splitting_tags' do
      document = '<document><meta><title>Title</title></meta>' \
                 '<content><par>First sentence. Second one.</par></content></document>'
      result = DeepL.translate(document, 'EN', 'ES',
                               { tag_handling: 'xml', split_sentences: 'nonewlines',
                                 outline_detection: false, splitting_tags: %w[title par] })

      expect(result).to be_a(DeepL::Resources::Text)
      expect(result.text).not_to be_empty
    end

    it 'translates using a glossary' do
      with_managed_glossary(name: 'Translate Glossary', source_lang: 'en', target_lang: 'de',
                            entries: [%w[Hello Hallo]]) do |glossary|
        result = DeepL.translate('Hello', 'EN', 'DE', { glossary_id: glossary.id })

        expect(result).to be_a(DeepL::Resources::Text)
        expect(result.text).not_to be_empty
      end
    end

    it 'translates using multiple glossaries via glossary_ids' do # rubocop:disable RSpec/ExampleLength
      with_managed_glossary(name: 'Translate Glossary IDs 1', source_lang: 'en', target_lang: 'de',
                            entries: [%w[Hello Hallo]]) do |glossary1|
        with_managed_glossary(name: 'Translate Glossary IDs 2', source_lang: 'en',
                              target_lang: 'de', entries: [%w[World Welt]]) do |glossary2|
          # Newly created glossaries can lag behind (eventual consistency), so
          # ensure they are resolvable before translating and tolerate a
          # transient "not found" on the translate call itself.
          wait_until_glossaries_ready(glossary1, glossary2)
          result = translate_retrying_missing_glossary(
            'Hello', 'EN', 'DE', { glossary_ids: [glossary1.id, glossary2.id] }
          )

          expect(result).to be_a(DeepL::Resources::Text)
          expect(result.text).not_to be_empty
        end
      end
    end

    %w[quality_optimized latency_optimized prefer_quality_optimized].each do |model_type|
      it "returns model_type_used for #{model_type}" do
        result = DeepL.translate(text, 'EN', 'DE', { model_type: model_type })

        expect(result).to be_a(DeepL::Resources::Text)
        expect(result.model_type_used).not_to be_nil
      end
    end

    %w[v1 v2].each do |version|
      it "translates with tag_handling_version #{version}" do
        result = DeepL.translate('<p>Hello world</p>', 'EN', 'DE',
                                 { tag_handling: 'html', tag_handling_version: version })

        expect(result).to be_a(DeepL::Resources::Text)
        expect(result.text).not_to be_empty
      end
    end
  end
end
