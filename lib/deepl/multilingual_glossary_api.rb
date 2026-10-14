# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  class MultilingualGlossaryApi
    def initialize(api, options = {})
      @api = api
      @options = options
    end

    def create(name, dictionaries, options = {})
      DeepL::Requests::MultilingualGlossary::Create.new(@api, name, dictionaries, options).request
    end

    def create_with_csv(name, source_lang, target_lang, csv_content, options = {})
      dictionaries = [{
        source_lang: source_lang,
        target_lang: target_lang,
        entries: csv_content,
        entries_format: 'csv'
      }]
      DeepL::Requests::MultilingualGlossary::Create.new(@api, name, dictionaries, options).request
    end

    def find(glossary_id, options = {})
      DeepL::Requests::MultilingualGlossary::Find.new(@api, glossary_id, options).request
    end

    def list(options = {})
      DeepL::Requests::MultilingualGlossary::List.new(@api, options).request
    end

    def entries(glossary_id, source_lang, target_lang, options = {})
      DeepL::Requests::MultilingualGlossary::Entries.new(@api, glossary_id, source_lang,
                                                         target_lang, options).request
    end

    def destroy(glossary_id, options = {})
      DeepL::Requests::MultilingualGlossary::Destroy.new(@api, glossary_id, options).request
    end

    def destroy_dictionary(glossary_id, source_lang, target_lang, options = {})
      DeepL::Requests::MultilingualGlossary::DestroyDictionary.new(@api, glossary_id, source_lang,
                                                                   target_lang, options).request
    end

    def replace_dictionary(glossary_id, source_lang, target_lang, entries, options = {})
      DeepL::Requests::MultilingualGlossary::ReplaceDictionary.new(@api, glossary_id, source_lang,
                                                                   target_lang, entries,
                                                                   options).request
    end

    def replace_dictionary_with_csv(glossary_id, source_lang, target_lang, csv_content,
                                    options = {})
      options = options.merge(entries_format: 'csv')
      DeepL::Requests::MultilingualGlossary::ReplaceDictionary.new(@api, glossary_id, source_lang,
                                                                   target_lang, csv_content,
                                                                   options).request
    end

    def update_name(glossary_id, name, options = {})
      DeepL::Requests::MultilingualGlossary::UpdateName.new(@api, glossary_id, name,
                                                            options).request
    end

    def update_dictionary(glossary_id, source_lang, target_lang, entries, options = {})
      DeepL::Requests::MultilingualGlossary::UpdateDictionary.new(@api, glossary_id, source_lang,
                                                                  target_lang, entries,
                                                                  options).request
    end

    def update_dictionary_with_csv(glossary_id, source_lang, target_lang, csv_content, options = {})
      options = options.merge(entries_format: 'csv')
      DeepL::Requests::MultilingualGlossary::UpdateDictionary.new(@api, glossary_id, source_lang,
                                                                  target_lang, csv_content,
                                                                  options).request
    end
  end
end
