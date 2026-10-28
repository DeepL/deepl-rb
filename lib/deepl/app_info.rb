# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  ##
  # Identifies your application in the +User-Agent+ header as +<app_name>/<app_version>+.
  AppInfo = Struct.new(:app_name, :app_version, keyword_init: true) do
    # Accepts an AppInfo or a hash with +:app_name+ and +:app_version+.
    def self.from(value)
      return nil if value.nil?
      return value if value.is_a?(AppInfo)
      raise ArgumentError, 'app_info must be a DeepL::AppInfo or a Hash' unless value.is_a?(Hash)

      new(app_name: value[:app_name] || value['app_name'],
          app_version: value[:app_version] || value['app_version'])
    end
  end
end
