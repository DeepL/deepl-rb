# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::Resources::TranslationMemorySegments do
  subject(:segments_page) { described_class.new(response, nil, nil) }

  let(:response) do
    {
      'segments' => [
        {
          'source_segment_id' => 'tm-1-source-0',
          'source_text' => 'Quelltext Nummer 0',
          'creation_time' => '2026-01-01T00:00:00Z',
          'updated_time' => '2026-01-02T00:00:00Z',
          'last_used_time' => '2026-01-03T00:00:00Z',
          'targets' => [
            {
              'target_segment_id' => 'tm-1-target-en-0',
              'target_language' => 'en',
              'target_text' => 'Source text number 0',
              'creation_time' => '2026-01-01T00:00:00Z',
              'updated_time' => '2026-01-02T00:00:00Z',
              'last_used_time' => '2026-01-03T00:00:00Z'
            }
          ]
        }
      ],
      'segment_count' => 12,
      'next_page_cursor' => 'NQ'
    }
  end

  describe '#initialize' do
    it 'creates a resource' do
      expect(segments_page).to be_a(described_class)
    end

    it 'assigns the page level attributes' do
      expect(segments_page.segment_count).to eq(12)
      expect(segments_page.next_page_cursor).to eq('NQ')
      expect(segments_page.next_page?).to be(true)
      expect(segments_page.to_s).to eq('1 of 12 segment(s)')
    end

    it 'maps the segments into resources' do
      segment = segments_page.segments.first
      expect(segment).to be_a(DeepL::Resources::TranslationMemorySegment)
      expect(segment.source_segment_id).to eq('tm-1-source-0')
      expect(segment.source_text).to eq('Quelltext Nummer 0')
      expect(segment.creation_time).to eq(Time.parse('2026-01-01T00:00:00Z'))
      expect(segment.updated_time).to eq(Time.parse('2026-01-02T00:00:00Z'))
      expect(segment.last_used_time).to eq(Time.parse('2026-01-03T00:00:00Z'))
    end

    it 'maps the target segments into resources' do
      target = segments_page.segments.first.targets.first
      expect(target).to be_a(DeepL::Resources::TranslationMemoryTargetSegment)
      expect(target.target_segment_id).to eq('tm-1-target-en-0')
      expect(target.target_language).to eq('en')
      expect(target.target_text).to eq('Source text number 0')
      expect(target.to_s).to eq('en: Source text number 0')
    end
  end

  context 'when the response is the last page' do
    let(:response) { { 'segments' => [], 'segment_count' => 12 } }

    it 'reports no further page' do
      expect(segments_page.segments).to eq([])
      expect(segments_page.next_page_cursor).to be_nil
      expect(segments_page.next_page?).to be(false)
    end
  end
end
