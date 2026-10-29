# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Exceptions
    # @deprecated The library no longer raises it: +DeepL::Resources::Language#supports_formality?+
    #   returns +nil+ for source languages instead.
    class NotSupported < Error
      def initialize(msg = 'The feature is not supported')
        Deprecation.warn_once('DeepL::Exceptions::NotSupported',
                              '[DEPRECATION] DeepL::Exceptions::NotSupported is deprecated, ' \
                              'the library no longer raises it.')
        super
      end
    end
  end
end
