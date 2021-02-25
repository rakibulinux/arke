# frozen_string_literal: true

module Arke::Exchange
  class Finex < Opendax
    def initialize(config)
      super
      @finex = true
      @bulk_order_support = config["bulk_order_support"] != false
      @bulk_limit = config["bulk_limit"] || 100
    end

    def stop_order_bulk(orders)
      orders.in_groups_of(@bulk_limit, false) do |orders_group|
        url = "#{@finex_route}/market/bulk/orders_by_id"
        response = delete(url, orders_group.map(&:id))
        if response.body.is_a?(Hash) && response.body["errors"]
          raise response.body["errors"].to_s
        end

        # Hotfix to prevent arke to try to cancel in loop already canceled orders
        orders_group.each {|order| notify_deleted_order(order) }
      end
    end
  end
end
