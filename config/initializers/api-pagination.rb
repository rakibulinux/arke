ApiPagination.configure do |config|
  config.paginator = :kaminari # or :will_paginate
  config.total_header = 'X-Total-Count'
  config.per_page_header = 'X-Per-Page'
  config.page_header = 'X-Page'

  config.response_formats = [:json, :xml, :jsonapi]
  config.page_param = :page
  config.per_page_param = :limit
end
