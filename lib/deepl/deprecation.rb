# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  # @api private
  module Deprecation
    @warned = {}
    @mutex = Mutex.new

    # Prints +message+ once per process for +key+. +uplevel+ 2 points the warning at the caller
    # of the deprecated method.
    def self.warn_once(key, message, uplevel: 2)
      first = @mutex.synchronize { @warned[key] ? false : (@warned[key] = true) }
      Kernel.warn(message, uplevel: uplevel) if first
    end

    # Like +warn_once+, but points the warning at the first caller outside the library, for
    # deprecated options that are read deep inside a request.
    def self.warn_once_at_caller(key, message)
      lib_dir = File.expand_path('..', __dir__)
      locations = caller_locations(1) || []
      index = locations.index { |loc| !loc.absolute_path.to_s.start_with?(lib_dir) }
      warn_once(key, message, uplevel: (index || 0) + 2)
    end
  end
end
