# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  # @deprecated Use the multilingual glossary methods of DeepL::Client instead.
  class MultilingualGlossaryApi
    def initialize(api, options = {})
      @api = api
      @options = options
    end

    # @deprecated Use DeepL::Client#create_multilingual_glossary instead.
    def create(name, dictionaries, options = {})
      DeepL::Requests::MultilingualGlossary::Create.new(@api, name, dictionaries, options).request
    end

    # @deprecated Use DeepL::Client#create_multilingual_glossary_from_csv instead.
    def create_with_csv(name, source_lang, target_lang, csv_content, options = {})
      dictionaries = [csv_dictionary(source_lang, target_lang, csv_content)]
      DeepL::Requests::MultilingualGlossary::Create.new(@api, name, dictionaries, options).request
    end

    # @deprecated Use DeepL::Client#get_multilingual_glossary instead.
    def find(glossary, options = {})
      DeepL::Requests::MultilingualGlossary::Find.new(@api, glossary, options).request
    end

    # @deprecated Use DeepL::Client#list_multilingual_glossaries instead.
    def list(options = {})
      DeepL::Requests::MultilingualGlossary::List.new(@api, options).request
    end

    # @deprecated Use DeepL::Client#get_multilingual_glossary_dictionary_entries instead.
    def entries(glossary, source_lang, target_lang, options = {})
      DeepL::Requests::MultilingualGlossary::Entries.new(@api, glossary, source_lang,
                                                         target_lang, options).request
    end

    # @deprecated Use DeepL::Client#delete_multilingual_glossary instead.
    def destroy(glossary, options = {})
      DeepL::Requests::MultilingualGlossary::Destroy.new(@api, glossary, options).request
    end

    # @deprecated Use DeepL::Client#delete_multilingual_glossary_dictionary instead.
    def destroy_dictionary(glossary, source_lang, target_lang, options = {})
      DeepL::Requests::MultilingualGlossary::DestroyDictionary.new(@api, glossary, source_lang,
                                                                   target_lang, options).request
    end

    # @deprecated Use DeepL::Client#replace_multilingual_glossary_dictionary instead.
    def replace_dictionary(glossary, source_lang, target_lang, entries, options = {})
      dictionary = { source_lang: source_lang, target_lang: target_lang, entries: entries }
      DeepL::Requests::MultilingualGlossary::ReplaceDictionary.new(@api, glossary, dictionary,
                                                                   options).request
    end

    # @deprecated Use DeepL::Client#replace_multilingual_glossary_dictionary_from_csv instead.
    def replace_dictionary_with_csv(glossary, source_lang, target_lang, csv_content,
                                    options = {})
      dictionary = csv_dictionary(source_lang, target_lang, csv_content)
      DeepL::Requests::MultilingualGlossary::ReplaceDictionary.new(@api, glossary, dictionary,
                                                                   options).request
    end

    # @deprecated Use DeepL::Client#update_multilingual_glossary_name instead.
    def update_name(glossary, name, options = {})
      DeepL::Requests::MultilingualGlossary::Update.new(@api, glossary, name, nil, options).request
    end

    # @deprecated Use DeepL::Client#update_multilingual_glossary_dictionary instead.
    def update_dictionary(glossary, source_lang, target_lang, entries, options = {})
      dictionary = { source_lang: source_lang, target_lang: target_lang, entries: entries }
      DeepL::Requests::MultilingualGlossary::Update.new(@api, glossary, nil, [dictionary],
                                                        options).request
    end

    # @deprecated Use DeepL::Client#update_multilingual_glossary_dictionary_from_csv instead.
    def update_dictionary_with_csv(glossary, source_lang, target_lang, csv_content, options = {})
      dictionary = csv_dictionary(source_lang, target_lang, csv_content)
      DeepL::Requests::MultilingualGlossary::Update.new(@api, glossary, nil, [dictionary],
                                                        options).request
    end

    private

    def csv_dictionary(source_lang, target_lang, csv_content)
      { source_lang: source_lang, target_lang: target_lang, entries: csv_content,
        entries_format: 'csv' }
    end
  end
end
