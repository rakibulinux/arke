# frozen_string_literal: true

describe Arke::ETL::Extract::PeatioAMQP do
  let(:trade_event) do
    [
      double(routing_key: "public.fthusd.trades"),
      {},
      {
        "trades" => [
          {"tid" => 1386, "taker_type" => "sell", "date" => 1_571_997_959, "price" => "100.0", "amount" => "0.5"}
        ]
      }.to_json
    ]
  end

  let(:tickers) do
    [
      double(routing_key: "public.global.tickers"),
      {},
      {
        "ethusd"  => {"name" => "ETH/USD", "base_unit" => "eth", "quote_unit" => "usd", "low" => "0.0", "high" => "0.0", "last" => "0.0", "at" => 1_571_997_958, "open" => "0.0", "volume" => "0.0", "sell" => "0.0", "buy" => "0.0", "avg_price" => "0.0", "price_change_percent" => "+0.00%"},
        "fthusd"  => {"name" => "FTH/USD", "base_unit" => "fth", "quote_unit" => "usd", "low" => "0.0", "high" => "0.0", "last" => "193.16", "at" => 1_571_997_958, "open" => 193.16, "volume" => "0.0", "sell" => "0.0", "buy" => "100.0", "avg_price" => "0.0", "price_change_percent" => "+0.00%"},
        "kyneth"  => {"name" => "KYN/ETH", "base_unit" => "kyn", "quote_unit" => "eth", "low" => "0.0", "high" => "0.0", "last" => "0.0", "at" => 1_571_997_958, "open" => "0.0", "volume" => "0.0", "sell" => "0.0", "buy" => "0.0", "avg_price" => "0.0", "price_change_percent" => "+0.00%"},
        "trsteth" => {"name" => "TRST/ETH", "base_unit" => "trst", "quote_unit" => "eth", "low" => "0.0", "high" => "0.0", "last" => "0.0", "at" => 1_571_997_958, "open" => "0.0", "volume" => "0.0", "sell" => "0.0", "buy" => "0.0", "avg_price" => "0.0", "price_change_percent" => "+0.00%"}
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

  it "filters out non trades events" do
    cb = double(call: true).method(:call).to_proc
    extract.mount(&cb)
    extract.on_event(*tickers)
    expect(cb).not_to receive(:call)
  end

  it "converts event to PublicTrade object" do
    public_trade = Arke::PublicTrade.new(1386, "fthusd", :sell, "0.5", "100.0", 1_571_997_959_000)
    cb = double(call: true).method(:call).to_proc
    expect(cb).to receive(:call).with(public_trade)

    extract.mount(&cb)
    extract.on_event(*trade_event)
  end
end
