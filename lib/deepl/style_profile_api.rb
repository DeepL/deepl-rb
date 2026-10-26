# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  # Manages style profiles (+/v3/style_profiles+): named sets of glossaries, style rule lists and
  # translation memories. Every method that takes +id+ accepts a style profile ID string or a
  # DeepL::Resources::StyleProfile object.
  #
  # In +create+ and +update+, a keyword left +nil+ is not sent. An empty string is sent and
  # clears +description+ or +industry+; an empty array is sent and unlinks all components of
  # that kind.
  class StyleProfileApi
    def initialize(api, options = {})
      @api = api
      @options = options
    end

    ##
    # Lists style profiles, one page at a time.
    #
    # @param [Hash] options Additional options:
    #   * +:page+ - Index of the page to return, starting at 0 (API default: 0).
    #   * +:page_size+ - Maximum number of style profiles per page (API default: 10; values
    #     above 100 are reduced to 100).
    # @return [Array<DeepL::Resources::StyleProfile>]
    def list(options = {})
      Requests::StyleProfile::List.new(@api, options).request
    end

    ##
    # Creates a style profile. Only +name+ is required. If any of the component IDs cannot be
    # used, the request fails and no style profile is created.
    #
    # @param [String] name Name of the style profile.
    # @param [String, nil] description Free-text description.
    # @param [String, nil] industry The industry the style profile is written for.
    # @param [Array<String>, nil] glossary_ids IDs of the glossaries to link, highest priority
    #   first.
    # @param [Array<String>, nil] style_rule_ids IDs of the style rule lists to link.
    # @param [Array<String>, nil] translation_memory_ids IDs of the translation memories to link.
    # @param [Boolean, nil] glossary_priority_order_enabled Whether the order of +glossary_ids+
    #   sets priority.
    # @param [Hash] options Additional options, such as +:extra_body_parameters+, given as
    #   further keywords.
    # @return [DeepL::Resources::StyleProfile] The created style profile.
    def create(name, description: nil, industry: nil, glossary_ids: nil, # rubocop:disable Metrics/ParameterLists
               style_rule_ids: nil, translation_memory_ids: nil,
               glossary_priority_order_enabled: nil, **options)
      fields = { description: description, industry: industry, glossary_ids: glossary_ids,
                 style_rule_ids: style_rule_ids, translation_memory_ids: translation_memory_ids,
                 glossary_priority_order_enabled: glossary_priority_order_enabled }
      Requests::StyleProfile::Create.new(@api, name, fields, options).request
    end

    ##
    # Retrieves a style profile.
    #
    # @return [DeepL::Resources::StyleProfile]
    # @raise [ArgumentError] If +id+ is empty.
    # @raise [DeepL::Exceptions::NotFound] If the style profile does not exist.
    def find(id, options = {})
      Requests::StyleProfile::Find.new(@api, id, options).request
    end

    ##
    # Updates a style profile. Keywords left +nil+ are not sent and leave the field unchanged;
    # with no keyword set, nothing changes. An empty string clears +description+ or +industry+.
    # A component list replaces the linked list in full; an empty array unlinks all components
    # of that kind.
    #
    # @param [String, nil] name New name.
    # @param [String, nil] description New description, or +''+ to clear it.
    # @param [String, nil] industry New industry, or +''+ to clear it.
    # @param [Array<String>, nil] glossary_ids Glossary IDs, highest priority first.
    # @param [Array<String>, nil] style_rule_ids Style rule list IDs.
    # @param [Array<String>, nil] translation_memory_ids Translation memory IDs.
    # @param [Boolean, nil] glossary_priority_order_enabled Whether the order of +glossary_ids+
    #   sets priority.
    # @param [Hash] options Additional options, such as +:extra_body_parameters+, given as
    #   further keywords.
    # @return [DeepL::Resources::StyleProfile] The updated style profile.
    # @raise [ArgumentError] If +id+ is empty.
    def update(id, name: nil, description: nil, industry: nil, glossary_ids: nil, # rubocop:disable Metrics/ParameterLists
               style_rule_ids: nil, translation_memory_ids: nil,
               glossary_priority_order_enabled: nil, **options)
      fields = { name: name, description: description, industry: industry,
                 glossary_ids: glossary_ids, style_rule_ids: style_rule_ids,
                 translation_memory_ids: translation_memory_ids,
                 glossary_priority_order_enabled: glossary_priority_order_enabled }
      Requests::StyleProfile::Update.new(@api, id, fields, options).request
    end

    ##
    # Deletes a style profile.
    #
    # @return [String] The ID of the deleted style profile.
    # @raise [ArgumentError] If +id+ is empty.
    def destroy(id, options = {})
      Requests::StyleProfile::Destroy.new(@api, id, options).request
    end
  end
end
