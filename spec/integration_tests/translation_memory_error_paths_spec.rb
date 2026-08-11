# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::TranslationMemoryApi, :mock_server_only do # rubocop:disable RSpec/SpecFilePathFormat
  include_context 'with a live mock server'

  let(:default_tm_id) { 'a74d88fb-ed2a-4943-a664-a4512398b994' }
  let(:missing_uuid) { '00000000-0000-0000-0000-000000000000' }

  describe 'authorization failures' do
    let(:unauthorized_translation_memories) { described_class.new(unauthorized_api) }

    it 'raises AuthorizationFailed when listing with an invalid auth key' do
      expect { unauthorized_translation_memories.list }
        .to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end

    it 'raises AuthorizationFailed on a read operation (find)' do
      expect { unauthorized_translation_memories.find(default_tm_id) }
        .to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end

    it 'raises AuthorizationFailed on a write operation (create_export)' do
      expect { unauthorized_translation_memories.create_export(default_tm_id) }
        .to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end
  end

  describe 'not-found failures' do
    it 'raises NotFound when #find is called with a missing UUID' do
      expect { DeepL.translation_memories.find(missing_uuid) }
        .to raise_error(DeepL::Exceptions::NotFound)
    end

    it 'raises NotFound when #segments is called with a missing UUID' do
      expect { DeepL.translation_memories.segments(missing_uuid) }
        .to raise_error(DeepL::Exceptions::NotFound)
    end

    it 'raises NotFound when #find_job is called with a missing UUID' do
      expect { DeepL.translation_memories.find_job(missing_uuid) }
        .to raise_error(DeepL::Exceptions::NotFound)
    end
  end

  describe 'bad-request failures' do
    it 'raises BadRequest when #segments is called with a too short text filter' do
      expect { DeepL.translation_memories.segments(default_tm_id, filter_text: 'a') }
        .to raise_error(DeepL::Exceptions::BadRequest)
    end

    it 'raises an error when #destroy is called with a malformed UUID' do
      expect { DeepL.translation_memories.destroy('invalid-uuid') }
        .to raise_error(DeepL::Exceptions::Error)
    end
  end

  describe 'client-side validation failures' do
    it 'raises an error when #find is called with an empty ID' do
      expect { DeepL.translation_memories.find('') }
        .to raise_error(DeepL::Exceptions::Error, /must not be empty/)
    end

    it 'raises an error when #find_job is called with an empty job ID' do
      expect { DeepL.translation_memories.find_job(nil) }
        .to raise_error(DeepL::Exceptions::Error, /must not be empty/)
    end

    it 'raises an error when #import_from_filepath is given a missing file' do
      expect { DeepL.translation_memories.import_from_filepath('/no/such/file.tmx') }
        .to raise_error(DeepL::Exceptions::Error, /No file found/)
    end

    it 'raises an error when #download_export is given an unfinished job' do
      created = DeepL.translation_memories.create_export(default_tm_id)
      job = DeepL::Resources::TranslationMemoryJob.new(
        { 'job_id' => created.job_id, 'results' => [{ 'status' => 'processing' }] }, nil, nil
      )
      expect { DeepL.translation_memories.download_export(job, '/tmp/unused.tmx') }
        .to raise_error(DeepL::Exceptions::Error, /no download URL/)
    end
  end
end
