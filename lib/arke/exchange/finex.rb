# frozen_string_literal: true

module Arke::Exchange
  class Finex < Opendax
    def initialize(config)
      super
      @finex = true
      @bulk_order_support = config["bulk_order_support"] != false
      @bulk_limit = config["bulk_limit"] || 100
    end

    def stop_order_bulk(orders_ids)
      orders_ids.in_groups_of(@bulk_limit, false) do |ids|
        url = "#{@finex_route}/market/bulk/orders_by_id"
        response = delete(url, ids)
        if response.body.is_a?(Hash) && response.body["errors"]
          raise response.body["errors"].to_s
        end
      end
    end
  end
end
