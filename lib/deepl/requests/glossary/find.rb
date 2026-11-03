# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Glossary
      class Find < Base
        METHOD = 'GET'

        def request
          build_glossary(*execute_request_with_retries(get_request))
        end

        private

        def build_glossary(request, response)
          Resources::Glossary.new(JSON.parse(response.body), request, response)
        end

        def path
          glossary_path
        end
      end
    end
  end
end
