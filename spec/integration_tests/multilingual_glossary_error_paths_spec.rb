# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'spec_helper'

describe DeepL::MultilingualGlossaryApi do # rubocop:disable RSpec/SpecFilePathFormat
  include_context 'with a live mock server'

  let(:nonexistent_glossary_id) { '00000000-0000-0000-0000-000000000000' }

  let(:valid_dictionaries) do
    [{ source_lang: 'en', target_lang: 'de', entries: [%w[Hello Hallo]] }]
  end

  describe 'AuthorizationFailed (401/403)' do
    let(:unauthorized_glossaries) { described_class.new(unauthorized_api) }

    it 'is raised by #list when the auth key is invalid' do
      expect { unauthorized_glossaries.list }
        .to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end

    it 'is raised by #create when the auth key is invalid' do
      expect { unauthorized_glossaries.create('Error Path Glossary', valid_dictionaries) }
        .to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end

    it 'is raised by #find when the auth key is invalid' do
      expect { unauthorized_glossaries.find(nonexistent_glossary_id) }
        .to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end

    it 'is raised by #destroy when the auth key is invalid' do
      expect { unauthorized_glossaries.destroy(nonexistent_glossary_id) }
        .to raise_error(DeepL::Exceptions::AuthorizationFailed)
    end
  end

  describe 'NotFound (404)' do
    it 'is raised by #find for a well-formed but unknown glossary id' do
      expect { DeepL.multilingual_glossaries.find(nonexistent_glossary_id) }
        .to raise_error(DeepL::Exceptions::NotFound)
    end

    it 'is raised by #destroy for a well-formed but unknown glossary id' do
      expect { DeepL.multilingual_glossaries.destroy(nonexistent_glossary_id) }
        .to raise_error(DeepL::Exceptions::NotFound)
    end

    it 'is raised by #entries for a well-formed but unknown glossary id' do
      expect { DeepL.multilingual_glossaries.entries(nonexistent_glossary_id, 'en', 'de') }
        .to raise_error(DeepL::Exceptions::NotFound)
    end
  end

  describe 'BadRequest (400) from #create' do
    it 'is raised for an invalid source language code' do
      dictionaries = [{ source_lang: 'zz', target_lang: 'de', entries: [%w[Hello Hallo]] }]
      expect { DeepL.multilingual_glossaries.create('Bad Lang Glossary', dictionaries) }
        .to raise_error(DeepL::Exceptions::BadRequest)
    end
  end

  describe 'BadRequest (400) from a malformed glossary id' do
    let(:malformed_uuid) { 'invalid-uuid' }

    it 'is raised by #find for a malformed glossary id' do
      expect { DeepL.multilingual_glossaries.find(malformed_uuid) }
        .to raise_error(DeepL::Exceptions::BadRequest)
    end

    it 'is raised by #destroy for a malformed glossary id' do
      expect { DeepL.multilingual_glossaries.destroy(malformed_uuid) }
        .to raise_error(DeepL::Exceptions::BadRequest)
    end
  end
end
