# frozen_string_literal: true

describe Arke::Fx::Static do
  let(:strategy) { Arke::Strategy::Copy.new([source], target, config, nil) }
  let(:source_account) { Arke::Exchange.create(source_config) }
  let(:target_account) { Arke::Exchange.create(target_config) }
  let(:source) { Arke::Market.new(config["sources"].first["market_id"], source_account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], target_account, Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS) }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:limit_asks_base) { 1.0 }
  let(:limit_bids_base) { 1.5 }
  let(:levels_size) { "0.01" }
  let(:levels_count) { "5" }
  let(:config) do
    {
      "type"    => "copy",
      "params"  => {
        "spread_bids"           => spread_bids,
        "spread_asks"           => spread_asks,
        "limit_bids_base"       => limit_bids_base,
        "limit_asks_base"       => limit_asks_base,
        "levels_algo"           => "constant",
        "levels_size"           => levels_size,
        "levels_count"          => levels_count,
        "side"                  => "both",
        "min_order_back_amount" => 0.001,
      },
      "target"  => {
        "account_id" => 2,
        "market_id"  => "BTCUSD",
      },
      "sources" => [
        {
          "account_id" => 1,
          "market_id"  => "BTCUSD",
        }
      ],
    }
  end

  let(:target_config) do
    {
      "id"     => 2,
      "driver" => "bitfaker",
    }
  end

  let(:source_config) do
    {
      "id"     => 1,
      "driver" => "bitfaker",
    }
  end

  let(:fx_config) do
    {
      "type" => "static",
      "rate" => rate,
    }
  end

  let(:fx) { ::Arke::Fx::Static.new(fx_config) }

  context "apply" do
    before(:each) do
      target.fetch_balances
      source.start
      source.update_orderbook
    end

    let(:rate) { 2.0 }

    it "applies the rate to orderbook and prices points" do
      ob, ppts = strategy.call
      expect(ob[:buy].to_hash).to eq(
        136.0044.to_d => (11_517_941_911_481_652.to_d * 1e-16),
        135.9848.to_d => (1_727_615_249_109_062.to_d * 1e-16),
        135.975.to_d  => (1_131_269_161_072_195.to_d * 1e-16),
        135.9652.to_d => 0.0527190829074743.to_d,
        135.9554.to_d => 0.0095982849262347.to_d
      )

      expect(ob[:sell].to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => 0.6656597259005248e0,
        (1_402_688.to_d * 1e-4)                  => 0.28941727213066e-2,
        (1_402_789.to_d * 1e-4)                  => 0.28941727213066e-2,
        (140_289.to_d * 1e-3)                    => 0.241726747017663e0,
        (1_402_977_264_909.to_d * 1e-10)         => 0.868251816391989e-1
      )

      expect(ppts).to eq(
        asks: [
          0.1402587e3,
          0.1402688e3,
          0.1402789e3,
          0.140289e3,
          0.1402991e3,
        ].map {|a| ::Arke::PricePoint.new(a) },
        bids: [
          0.1359946e3,
          0.1359848e3,
          0.135975e3,
          0.1359652e3,
          0.1359554e3,
        ].map {|a| ::Arke::PricePoint.new(a) }
      )

      fx_ob, fx_ppts = fx.apply(ob, ppts)

      expect(fx_ob[:buy].to_hash).to eq(
        (136.0044.to_d * rate) => (11_517_941_911_481_652.to_d * 1e-16),
        (135.9848.to_d * rate) => (1_727_615_249_109_062.to_d * 1e-16),
        (135.975.to_d * rate)  => (1_131_269_161_072_195.to_d * 1e-16),
        (135.9652.to_d * rate) => 0.0527190829074743.to_d,
        (135.9554.to_d * rate) => 0.0095982849262347.to_d
      )
      expect(fx_ob[:sell].to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16 * rate) => 0.6656597259005248e0,
        (1_402_688.to_d * 1e-4 * rate)                  => 0.28941727213066e-2,
        (1_402_789.to_d * 1e-4 * rate)                  => 0.28941727213066e-2,
        (140_289.to_d * 1e-3 * rate)                    => 0.241726747017663e0,
        (1_402_977_264_909.to_d * 1e-10 * rate)         => 0.868251816391989e-1
      )

      expect(fx_ppts).to eq(
        asks: [
          0.1402587e3,
          0.1402688e3,
          0.1402789e3,
          0.140289e3,
          0.1402991e3,
        ].map {|a| ::Arke::PricePoint.new(a * rate) },
        bids: [
          0.1359946e3,
          0.1359848e3,
          0.135975e3,
          0.1359652e3,
          0.1359554e3,
        ].map {|a| ::Arke::PricePoint.new(a * rate) }
      )
    end
  end
end
