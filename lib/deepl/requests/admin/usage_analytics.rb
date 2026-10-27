# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Admin
      class UsageAnalytics < Base
        def initialize(api, start_date, end_date, group_by = nil)
          super(api)
          @start_date = start_date
          @end_date = end_date
          @group_by = group_by
        end

        def request
          request, response = execute_request_with_retries(get_request)
          Resources::AdminUsageReport.new(parse_json_object(response), request, response)
        end

        private

        def query_params
          params = date_range_params(@start_date, @end_date)
          params['group_by'] = @group_by.to_s unless @group_by.nil?
          params
        end

        def path
          'admin/analytics'
        end
      end
    end
  end
end
