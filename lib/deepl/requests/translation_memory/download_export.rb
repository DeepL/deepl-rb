# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class DownloadExport < StorageBase
        def initialize(api, download_url, output_file)
          super(api, download_url)
          @output_file = output_file
        end

        def request
          extract_file(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def get_request # rubocop:disable Naming/AccessorMethodName
          Net::HTTP::Get.new(uri.request_uri, headers)
        end

        def extract_file(_request, response)
          File.binwrite(@output_file, response.body)
        end
      end
    end
  end
end
