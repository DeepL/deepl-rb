# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Glossary
      class Entries < Base
        METHOD = 'GET'

        def request
          _, response = execute_request_with_retries(get_request)
          Utils::GlossaryEntries.from_tsv(response.body)
        end

        private

        def get_request # rubocop:disable Naming/AccessorMethodName
          Net::HTTP::Get.new(uri.path, headers.merge('Accept' => 'text/tab-separated-values'))
        end

        def path
          glossary_path('entries')
        end
      end
    end
  end
end
