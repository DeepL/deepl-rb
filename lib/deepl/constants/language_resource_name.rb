# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Constants
    # Values of the +resource+ argument of +DeepL::Client#get_languages_for_resource+ and of
    # +DeepL::Resources::LanguageResource#name+. Other strings are accepted and sent unchanged, so
    # a resource the API adds later can be queried before it is listed here.
    class LanguageResourceName < BaseConstant
      TRANSLATE_TEXT = 'translate_text'
      TRANSLATE_DOCUMENT = 'translate_document'
      GLOSSARY = 'glossary'
      VOICE = 'voice'
      WRITE = 'write'
      STYLE_RULES = 'style_rules'
      TRANSLATION_MEMORY = 'translation_memory'
    end
  end
end
