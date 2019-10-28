# frozen_string_literal: true

describe Arke::ETL::Load::AMQP do
  let(:amqp) { Arke::ETL::Load::AMQP.new({}) }
  let(:public_trade_event) do
    [
      "public",
      "fthusd",
      "trades",
      {
        "trades" => [
          {"tid" => 1386, "taker_type" => "sell", "date" => 1_571_997_959, "price" => "100.0", "amount" => "0.5"}
        ]
      }
    ]
  end

  let(:public_trade) do
    Arke::PublicTrade.new(1386, "fthusd", :sell, "0.5", "100.0", 1_571_997_959_000)
  end

  context "receives public trade object" do
    it "converts to public trade event" do
      expect(amqp.convert(public_trade)).to eq(public_trade_event)
    end
  end

  context "receives unsupported object" do
    it "raises error" do
      expect { amqp.convert("some string") }.to raise_error(StandardError)
    end
  end
end
