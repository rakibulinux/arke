# frozen_string_literal: true

module Arke::ETL::Transform
  class Split < Base
    def call(object)
      object.data.each do |key, value|
        #<struct Arke::Ticker open=nil, low=nil, high=nil, last=nil, volume=nil, avg_price=nil, price_change_percent=nil, at=nil, market=nil>
        emit(Arke::Ticker.new(value[:open], value[:low], value[:high], value[:last], value[:volume], value[:avg_price], value[:price_change_percent], value[:at], key))
      end
    end
  end
end
