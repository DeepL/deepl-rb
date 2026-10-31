# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    # @deprecated Only the module-level API raises it, from
    #   +DeepL::Resources::Language#supports_formality?+ for a source language; DeepL::Client
    #   returns +nil+ instead.
    class NotSupported < Error
      def initialize(msg = 'The feature is not supported')
        Deprecation.warn_once('DeepL::Exceptions::NotSupported',
                              '[DEPRECATION] DeepL::Exceptions::NotSupported is deprecated, ' \
                              'only the module-level API raises it.')
        super
      end
    end
  end
end
