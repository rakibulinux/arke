# frozen_string_literal: true

describe Arke::ETL::Extract::PeatioAMQP do
  let(:trade_event) do
    [
      {},
      {
        "trades" => [
          {"tid" => 1386, "taker_type" => "sell", "date" => 1_571_997_959, "price" => "100.0", "amount" => "0.5"}
        ]
      }.to_json
    ]
  end

  let(:extract) do
    Arke::ETL::Extract::PeatioAMQP.new(
      "events" => [{
        "type"  => "public",
        "event" => "trades",
      }]
    )
  end

  it "mounts callbacks" do
    cb1 = double(call: true).method(:call).to_proc
    cb2 = double(call: true).method(:call).to_proc
    extract.mount(&cb1)
    extract.mount(&cb2)
    expect(extract.instance_variable_get(:@callbacks)).to eq([cb1, cb2])
  end

  # TODO: Fix this one
  xit "converts event to PublicTrade object" do
    public_trade = PublicTrade.new(id: 1386,
                                   market: "fthusd",
                                   taker_type: "sell",
                                   price: "100.0",
                                   amount: "0.5",
                                   exchange: "peatio",
                                   total: 50.to_d,
                                   created_at: 1_571_997_959_000)

    cb = double(call: true).method(:call).to_proc
    expect(cb).to receive(:call).with(public_trade)

    extract.mount(&cb)
    extract.on_event(*trade_event)
  end
end
