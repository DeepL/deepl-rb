# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  # Manages spoken terms collections (+/v3/spoken-terms+). Every method that takes +id+ accepts
  # a spoken terms ID string or a DeepL::Resources::SpokenTerms object.
  class SpokenTermsApi
    def initialize(api, options = {})
      @api = api
      @options = options
    end

    ##
    # Creates a spoken terms collection.
    #
    # @param [String] name Name of the collection.
    # @param [Array<DeepL::Resources::SpokenTermsEntries, Hash>] term_lists One entry per
    #   language. A hash needs the keys +:lang+ and +:entries+ (an array of terms).
    # @return [DeepL::Resources::SpokenTerms] The created collection.
    def create(name, term_lists, options = {})
      Requests::SpokenTerms::Create.new(@api, name, term_lists, options).request
    end

    ##
    # Lists all spoken terms collections.
    #
    # @return [Array<DeepL::Resources::SpokenTerms>]
    def list(options = {})
      Requests::SpokenTerms::List.new(@api, options).request
    end

    ##
    # Retrieves a spoken terms collection.
    #
    # @return [DeepL::Resources::SpokenTerms]
    # @raise [DeepL::Exceptions::NotFound] If the collection does not exist.
    def find(id, options = {})
      Requests::SpokenTerms::Find.new(@api, id, options).request
    end

    ##
    # Renames a collection and/or merges terms into its lists. Arguments left +nil+ are not sent.
    #
    # @param [String, nil] name New name.
    # @param [Array<DeepL::Resources::SpokenTermsEntries, Hash>, nil] term_lists Terms to merge
    #   into the list of each language; a new language adds a list.
    # @return [DeepL::Resources::SpokenTerms] The updated collection.
    def update(id, name: nil, term_lists: nil)
      Requests::SpokenTerms::Update.new(@api, id, name: name, term_lists: term_lists).request
    end

    ##
    # Retrieves the terms of one language.
    #
    # @param [String] lang Language code, for example +'en'+.
    # @return [DeepL::Resources::SpokenTermsEntries]
    def entries(id, lang, options = {})
      Requests::SpokenTerms::Entries.new(@api, id, lang, options).request
    end

    ##
    # Replaces the terms of one language, or adds the list if the language is new.
    #
    # @param [String] lang Language code, for example +'en'+.
    # @param [Array<String>] entries The terms.
    # @return [DeepL::Resources::SpokenTermsList]
    def replace_term_list(id, lang, entries, options = {})
      Requests::SpokenTerms::ReplaceTermList.new(@api, id, lang, entries, options).request
    end

    ##
    # Deletes a spoken terms collection.
    #
    # @return [String] The ID of the deleted collection.
    def destroy(id, options = {})
      Requests::SpokenTerms::Destroy.new(@api, id, options).request
    end

    ##
    # Deletes the term list of one language.
    #
    # @param [String] lang Language code, for example +'en'+.
    # @return [String] The language of the deleted list.
    def destroy_term_list(id, lang, options = {})
      Requests::SpokenTerms::DestroyTermList.new(@api, id, lang, options).request
    end
  end
end
