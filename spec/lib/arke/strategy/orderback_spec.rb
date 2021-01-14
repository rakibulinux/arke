# frozen_string_literal: true


describe Arke::Strategy::Orderback do
  let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config, nil) }
  let(:account) { Arke::Exchange.create(account_config) }
  let(:source) { Arke::Market.new(config["sources"].first["market_id"], account, Arke::Helpers::Flags::DEFAULT_SOURCE_FLAGS) }
  let(:target) { Arke::Market.new(config["target"]["market_id"], account, Arke::Helpers::Flags::DEFAULT_TARGET_FLAGS) }
  let(:side) { "both" }
  let(:spread_asks) { 0.01 }
  let(:spread_bids) { 0.02 }
  let(:limit_asks_base) { 1.0 }
  let(:limit_bids_base) { 1.5 }
  let(:orderback_grace_time) { nil }
  let(:orderback_type) { nil }
  let(:enable_orderback) { "true" }
  let(:fx_config) { nil }

  let(:config) do
    {
      "id"      => "orderback-BTCUSD",
      "type"    => "orderback",
      "params"  => {
        "spread_bids"           => spread_bids,
        "spread_asks"           => spread_asks,
        "limit_bids_base"       => limit_bids_base,
        "limit_asks_base"       => limit_asks_base,
        "levels_algo"           => "constant",
        "levels_size"           => 0.01,
        "levels_count"          => 5,
        "side"                  => side,
        "min_order_back_amount" => 0.001,
        "orderback_grace_time"  => orderback_grace_time,
        "orderback_type"        => orderback_type,
        "enable_orderback"      => enable_orderback,
      },
      "fx"      => fx_config,
      "target"  => {
        "account_id" => 1,
        "market_id"  => "BTCUSD",
      },
      "sources" => [
        "account_id" => 1,
        "market_id"  => "xbtusd",
      ],
    }
  end

  let(:account_config) do
    {
      "id"     => 1,
      "driver" => "bitfaker",
    }
  end
  let(:target_orderbook) { strategy.call }
  let(:target_bids) { target_orderbook.first[:buy] }
  let(:target_asks) { target_orderbook.first[:sell] }

  before(:each) do
    source.fetch_balances
    target.fetch_balances
    source.start
    source.update_orderbook
  end

  context "running both sides" do
    let(:side) { "both" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.052719082907474284.to_d,
        135.9750.to_d => (11_312_691_610_721_95.to_d * 1e-16),
        135.9848.to_d => (1_727_615_249_109_062.to_d * 1e-16),
        136.0044.to_d => (11_517_941_911_481_652.to_d * 1e-16)
      )
      expect(target_asks.to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6_656_597_259_005_248.to_d * 1e-16),
        140.2688.to_d                            => 0.0028941727213066.to_d,
        140.2789.to_d                            => 0.0028941727213066.to_d,
        140.2890.to_d                            => 0.241726747017663.to_d,
        140.2977264909.to_d                      => 0.0868251816391989.to_d
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq({})
      expect(target_asks.to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6_656_597_259_005_248.to_d * 1e-16),
        0.1402688e3.to_d                         => 0.28941727213066e-2.to_d,
        0.1402789e3.to_d                         => 0.28941727213066e-2.to_d,
        0.140289e3.to_d                          => 0.241726747017663e0.to_d,
        0.1402977264909e3.to_d                   => 0.868251816391989e-1.to_d
      )
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.527190829074743e-1.to_d,
        135.9750.to_d => (1_131_269_161_072_195.to_d * 1e-16),
        135.9848.to_d => (1_727_615_249_109_062.to_d * 1e-16),
        136.0044.to_d => (11_517_941_911_481_652.to_d * 1e-16)
      )
      expect(target_asks.to_hash).to eq({})
    end
  end

  context "running both sides with a spread" do
    let(:side) { "both" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6_656_597_259_005_248.to_d * 1e-16),
        0.1402688e3.to_d                         => 0.28941727213066e-2.to_d,
        0.1402789e3.to_d                         => 0.28941727213066e-2.to_d,
        0.140289e3.to_d                          => 0.241726747017663e0.to_d,
        0.1402977264909e3.to_d                   => 0.868251816391989e-1.to_d
      )
      expect(target_bids.to_hash).to eq(
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.527190829074743e-1.to_d,
        135.9750.to_d => (1_131_269_161_072_195.to_d * 1e-16),
        135.9848.to_d => (1_727_615_249_109_062.to_d * 1e-16),
        136.0044.to_d => (11_517_941_911_481_652.to_d * 1e-16)
      )
    end
  end

  context "running asks side only" do
    let(:side) { "asks" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_asks.to_hash).to eq(
        (1_402_573_826_086_956_521.to_d * 1e-16) => (6_656_597_259_005_248.to_d * 1e-16),
        0.1402688e3.to_d                         => 0.28941727213066e-2.to_d,
        0.1402789e3.to_d                         => 0.28941727213066e-2.to_d,
        0.140289e3.to_d                          => 0.241726747017663e0.to_d,
        0.1402977264909e3.to_d                   => 0.868251816391989e-1.to_d
      )
      expect(target_bids.to_hash).to eq({})
    end
  end

  context "running bids side only" do
    let(:side) { "bids" }
    let(:spread_asks) { 0.01 }
    let(:spread_bids) { 0.02 }

    it "outputs a target orberbook" do
      expect(target_bids.to_hash).to eq(
        135.9554.to_d => 0.95982849262347e-2.to_d,
        135.9652.to_d => 0.527190829074743e-1.to_d,
        135.9750.to_d => 1_131_269_161_072_195.to_d * 1e-16,
        135.9848.to_d => 1_727_615_249_109_062.to_d * 1e-16,
        136.0044.to_d => 11_517_941_911_481_652.to_d * 1e-16
      )

      expect(target_asks.to_hash).to eq({})
    end
  end

  context "callback method is functioning" do
    it "registers a callback" do
      expect(target.account.instance_variable_get(:@private_trades_cb).length).to eq(1)
    end
  end

  context "group_trades helper" do
    it "groups trades by price" do
      trades = {
        1 => {41 => ["ABC", 123.0, 10, :buy]},
        2 => {61 => ["ABC", 123.5, 20, :buy]},
        3 => {51 => ["ABC", 123.0, 15, :sell]},
        4 => {51 => ["ABC", 123.0, 15, :buy]},
      }
      expect(strategy.group_trades(trades)).to eq(
        [123.0, :buy]  => 25,
        [123.5, :buy]  => 20,
        [123.0, :sell] => 15
      )
    end
  end

  context "notify_private_trade" do
    let(:orderback_grace_time) { 0.002 }

    it "triggers a buy back to the source market" do
      order = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      target.add_order(order)
      trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 139.45, 69.725, 14)
      source.account.executor = double(:executor)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.5, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end

    it "triggers a sell back to the source market" do
      order = ::Arke::Order.new("BTCUSD", 98, 1, :buy, "limit", 14)
      target.add_order(order)
      trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 98, 49, 14)
      source.account.executor = double(:executor)

      orderb = ::Arke::Order.new("xbtusd", 100, 0.5, :sell, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "notify_private_trade called several times with trades of the same price" do
    let(:orderback_grace_time) { 0.002 }

    it "triggers one order back to the source market" do
      order = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      target.add_order(order)
      trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 139.45, nil, 14)
      trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 139.45, nil, 14)
      trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 139.45, nil, 14)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.6, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      source.account.executor = double(:executor)
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade1)
        strategy.notify_private_trade(trade2)
        strategy.notify_private_trade(trade3)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "notify_private_trade called several times with trades of different prices" do
    let(:orderback_grace_time) { 0.01 }

    it "triggers several orders back to the source" do
      order1 = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      order2 = ::Arke::Order.new("BTCUSD", 140.00, 1, :sell, "limit", 15)
      target.add_order(order1)
      target.add_order(order2)

      trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 139.45, nil, 14)
      trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 139.45, nil, 14)
      trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 140.00, nil, 15)

      orderb1 = ::Arke::Order.new("xbtusd", 138.069306, 0.3, :buy, "market")
      orderb2 = ::Arke::Order.new("xbtusd", 138.613861, 0.3, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb1),
        ::Arke::Action.new(:order_create, source, order: orderb2)
      ]
      source.account.executor = double(:executor)
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade1)
        strategy.notify_private_trade(trade2)
        strategy.notify_private_trade(trade3)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "notify_private_trade called several times with trades of same price but different orders" do
    let(:orderback_grace_time) { 0.01 }

    it "triggers several orders back to the source" do
      order1 = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      order2 = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 15)
      target.add_order(order1)
      target.add_order(order2)

      trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 139.45, nil, 14)
      trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 139.45, nil, 14)
      trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 139.45, nil, 15)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.6, :buy, "market")
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      source.account.executor = double(:executor)
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade1)
        strategy.notify_private_trade(trade2)
        strategy.notify_private_trade(trade3)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end
  end

  context "fx rate applied from the source prices" do
    let(:fx_config) do
      {
        "type" => "static",
        "rate" => 0.5,
      }
    end

    before(:each) do
      if config["fx"]
        type = config["fx"]["type"]
        fx_klass = Arke::Fx.const_get(type.capitalize)
        strategy.fx = fx_klass.new(config["fx"])
      end
    end

    context "notify_private_trade" do
      let(:orderback_grace_time) { 0.002 }

      it "triggers a buy back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        target.add_order(order)
        trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 101, 50.50, 14)
        source.account.executor = double(:executor)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.5, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end

      it "triggers a sell back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 98, 1, :buy, "limit", 14)
        target.add_order(order)
        trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 98, 49, 14)
        source.account.executor = double(:executor)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.5, :sell, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade with a different price from the order" do
      let(:orderback_grace_time) { 0.002 }

      it "triggers a buy back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        target.add_order(order)
        trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 102, 51, 14)
        source.account.executor = double(:executor)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.5, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of the same price" do
      let(:orderback_grace_time) { 0.002 }

      it "triggers one order back to the source market" do
        order = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        target.add_order(order)
        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 101, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 14)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of different prices" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 106.05, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 101, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 106.05, nil, 15)

        orderb1 = ::Arke::Order.new("xbtusd", 200, 0.3, :buy, "market")
        orderb2 = ::Arke::Order.new("xbtusd", 210, 0.3, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb1),
          ::Arke::Action.new(:order_create, source, order: orderb2)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of same price but different orders" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 101, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 15)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called several times with trades of same order price but different orders" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 102, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 15)

        orderb = ::Arke::Order.new("xbtusd", 200, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
        EM.synchrony do
          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
        end
      end
    end

    context "notify_private_trade called while the fx rate is not ready yet" do
      let(:orderback_grace_time) { 0.01 }

      it "triggers several orders back to the source" do
        order1 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 14)
        order2 = ::Arke::Order.new("BTCUSD", 101, 1, :sell, "limit", 15)
        target.add_order(order1)
        target.add_order(order2)

        trade1 = ::Arke::Trade.new(42, "BTCUSD", nil, 0.1, 101, nil, 14)
        trade2 = ::Arke::Trade.new(43, "BTCUSD", nil, 0.2, 102, nil, 14)
        trade3 = ::Arke::Trade.new(44, "BTCUSD", nil, 0.3, 101, nil, 15)

        orderb = ::Arke::Order.new("xbtusd", 2000, 0.6, :buy, "market")
        actions = [
          ::Arke::Action.new(:order_create, source, order: orderb)
        ]
        source.account.executor = double(:executor)
        expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)

        EM.synchrony do
          strategy.fx.instance_variable_set(:@rate, nil)

          strategy.notify_private_trade(trade1)
          strategy.notify_private_trade(trade2)
          strategy.notify_private_trade(trade3)
          EM::Synchrony.add_timer(0.5) { strategy.fx.instance_variable_set(:@rate, 0.05) }
          EM::Synchrony.add_timer(1.1) { EM.stop }
        end
      end
    end
  end

  context "orderback_type" do
    let(:orderback_grace_time) { 0.002 }

    def validate_orderback_type(type)
      order = ::Arke::Order.new("BTCUSD", 139.45, 1, :sell, "limit", 14)
      target.add_order(order)
      trade = ::Arke::Trade.new(42, "BTCUSD", nil, 0.5, 139.45, 69.725, 14)
      source.account.executor = double(:executor)

      orderb = ::Arke::Order.new("xbtusd", 138.069306, 0.5, :buy, type)
      actions = [
        ::Arke::Action.new(:order_create, source, order: orderb)
      ]
      expect(source.account.executor).to receive(:push).with("orderback-BTCUSD", actions)
      EM.synchrony do
        strategy.notify_private_trade(trade)
        EM::Synchrony.add_timer(orderback_grace_time * 2) { EM.stop }
      end
    end

    it "triggers a buy back with `market` order type as default to the source market" do
      validate_orderback_type("market")
    end

    context "orderback_type: limit" do
      let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config.merge("params" => config["params"].merge("orderback_type" => "limit")), nil) }

      it "triggers a buy back with `limit` order type to the source market" do
        validate_orderback_type("limit")
      end
    end

    context "orderback_type: market" do
      let!(:strategy) { Arke::Strategy::Orderback.new([source], target, config.merge("params" => config["params"].merge("orderback_type" => "market")), nil) }

      it "triggers a buy back with `market` order type to the source market" do
        validate_orderback_type("market")
      end
    end

    context "orderback_type: invalid" do
      it "should have the RuntimeError: orderback_type must be `limit` or `market`" do
        expect { Arke::Strategy::Orderback.new([source], target, config.merge("params" => config["params"].merge("orderback_type" => "invalid")), nil) }.to raise_error(RuntimeError, /orderback_type must be `limit` or `market`/)
      end
    end
  end
end
