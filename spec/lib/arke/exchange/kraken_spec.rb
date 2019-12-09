# frozen_string_literal: true

describe Arke::Exchange::Kraken do
  include_context "mocked kraken"
  let(:exchange_config) do
    {
      "driver" => "kraken",
    }
  end
  let(:kraken) { Arke::Exchange::Kraken.new(exchange_config) }
  let(:market_config) { {"id" => "XBTUSD"} }
  let!(:market) { Arke::Market.new(market_config, kraken) }

  context "market_config" do
    it "returns market configuration" do
      expect(kraken.market_config("XBTUSD")).to eq(
        "id"               => "XBTUSD",
        "base_unit"        => "XXBT",
        "quote_unit"       => "ZUSD",
        "min_price"        => nil,
        "max_price"        => nil,
        "min_amount"       => nil,
        "amount_precision" => 8,
        "price_precision"  => 1
      )
    end
  end
end
