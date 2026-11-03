# Copyright 2022 Daniel Herzog
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Glossary
      class Destroy < Base
        METHOD = 'DELETE'

        def request
          execute_request_with_retries(delete_request)
          nil
        end

        private

        def path
          glossary_path
        end
      end
    end
  end
end
