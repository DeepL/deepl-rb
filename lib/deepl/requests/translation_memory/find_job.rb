# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module TranslationMemory
      class FindJob < Base
        attr_reader :job_id

        def initialize(api, job_id, options = {})
          super(api, options)
          @job_id = job_id
        end

        def request
          build_job(*execute_request_with_retries(get_request))
        end

        def to_s
          "GET #{uri.request_uri}"
        end

        private

        def build_job(request, response)
          data = JSON.parse(response.body)
          Resources::TranslationMemoryJob.new(data, request, response)
        end

        def path
          "translation_memories/jobs/#{job_id}"
        end
      end
    end
  end
end
