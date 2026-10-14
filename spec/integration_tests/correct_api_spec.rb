# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe 'DeepL.correct' do # rubocop:disable RSpec/DescribeClass
  describe 'happy path' do
    it 'corrects an English sentence and returns a Text resource' do
      result = DeepL.correct('As Gregor Samsa awoke one morning he found himself transformed.',
                             'en')

      expect(result).to be_a(DeepL::Resources::Text)
      expect(result.text).to be_a(String)
      expect(result.text).not_to be_empty
    end
  end

  describe 'edge case' do
    it 'corrects an array of texts and returns an array of Text resources' do
      texts = [
        'As Gregor Samsa awoke one morning he found himself transformed.',
        'He lay on his armour-like back, and if he lifted his head a little.'
      ]

      results = DeepL.correct(texts, 'en')

      expect(results).to be_an(Array)
      expect(results.size).to eq(2)
      expect(results).to all(be_a(DeepL::Resources::Text))
      expect(results.map(&:text)).to all(be_a(String).and(satisfy { |t| !t.empty? }))
    end

    it 'returns an array for an array holding a single text' do
      results = DeepL.correct(['As Gregor Samsa awoke one morning he found himself transformed.'])

      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
    end

    it 'corrects a text without an explicit target_lang' do
      result = DeepL.correct('As Gregor Samsa awoke one morning he found himself transformed.')

      expect(result).to be_a(DeepL::Resources::Text)
      expect(result.text).to be_a(String)
      expect(result.text).not_to be_empty
    end
  end
end
