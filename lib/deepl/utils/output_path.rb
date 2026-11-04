# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Utils
    # Checks of an output file path before any request is sent.
    # @api private
    module OutputPath
      extend self

      # @raise [Errno::EEXIST] If +path+ exists.
      # @raise [Errno::ENOENT] If the directory of +path+ does not exist.
      # @raise [Errno::EACCES] If the directory of +path+ is not writable.
      def check!(path)
        raise Errno::EEXIST, path.to_s if File.exist?(path)

        directory = File.dirname(path)
        raise Errno::ENOENT, directory unless File.directory?(directory)
        raise Errno::EACCES, directory unless File.writable?(directory)
      end
    end
  end
end
