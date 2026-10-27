# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE.md file.
# frozen_string_literal: true

module DeepL
  module Requests
    module Admin
      class CustomTagUsageAnalytics < Base
        def initialize(api, start_date, end_date, aggregate_by = nil, page = nil)
          super(api)
          @start_date = start_date
          @end_date = end_date
          @aggregate_by = aggregate_by
          @page = page
        end

        def request
          request, response = execute_request_with_retries(get_request)
          Resources::CustomTagUsageReport.new(parse_json_object(response), request, response)
        end

        private

        def query_params
          params = date_range_params(@start_date, @end_date)
          params['aggregate_by'] = @aggregate_by.to_s unless @aggregate_by.nil?
          params['page'] = @page.to_s unless @page.nil?
          params
        end

        def path
          'admin/analytics/custom-tags'
        end
      end
    end
  end
end
