describe Arke::Exchange::Tradepoint do
  let(:tp) {
    Arke::Exchange::Tradepoint.new(
      "ws" => "ws://localhost:5050",
      "markets" => ["alpha.yellow.org:btcusd"],
    )
  }

  before do
    ENV["DAPR_HTTP_PORT"] = "1234"
  end


  context "initialize orderbook" do

    before do
      sequence = 12
      asks = [
        ["0.4259916e5","0.104e-2"],
        ["0.4256372e5","0.307485e1"],
        ["0.4252598e5","0.21941e0"],
        ["0.4252346e5","0.89235e0"]
      ]
      bids = [
        ["0.4236536e5","0.1301232e2"],
        ["0.4241821e5","0.577107e1"],
        ["0.4241929e5","0.263796e1"],
        ["0.4245432e5","0.328781e1"],
      ]
      stub_request(:post, "http://localhost:1234/v1.0/invoke/exchange-arke/method/orderbook").
      with(
        body: "market=btcusd&id=alpha.yellow.org",
        headers: {
        'Content-Type'=>'application/json'
        }).
      to_return(
        status:  200,
        body: [sequence, asks, bids].to_json,
        headers: {}
      )
      tp.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_ORDERBOOK)
    end

    it "bufferizes increments received before the snapshot and apply them on top of snapshot" do
      tp.instance_variable_set(:@original_fetch_orderbook, tp.method(:fetch_orderbook))

      def tp.fetch_orderbook(stream, market)
        handle_ob_inc(stream, market, 13, [["0.4251346e5","0.89242e0"]], [])
        handle_ob_inc(stream, market, 14, [["0.4250346e5","0.89254e0"]], [["0.4226536e5","0.1301298e2"]])
        @original_fetch_orderbook.call(stream, market)
      end

      tp.ws_connect_public

      expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(14)
      expect(tp.books["alpha.yellow.org:btcusd"][:book][:sell].to_a).to eq([
        ["0.4250346e5".to_d, "0.89254e0".to_d],
        ["0.4251346e5".to_d, "0.89242e0".to_d],
        ["0.4252346e5".to_d, "0.89235e0".to_d],
        ["0.4252598e5".to_d, "0.21941e0".to_d],
        ["0.4256372e5".to_d, "0.307485e1".to_d],
        ["0.4259916e5".to_d, "0.104e-2".to_d],
      ])

      expect(tp.books["alpha.yellow.org:btcusd"][:book][:buy].to_a).to eq([
        ["0.4245432e5".to_d, "0.328781e1".to_d],
        ["0.4241929e5".to_d, "0.263796e1".to_d],
        ["0.4241821e5".to_d, "0.577107e1".to_d],
        ["0.4236536e5".to_d, "0.1301232e2".to_d],
        ["0.4226536e5".to_d, "0.1301298e2".to_d],
      ])
    end

    it "works without any increment to add to the snapshot" do
      tp.ws_connect_public
      expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(12)
      expect(tp.books["alpha.yellow.org:btcusd"][:book][:sell].to_a).to eq([
        ["0.4252346e5".to_d, "0.89235e0".to_d],
        ["0.4252598e5".to_d, "0.21941e0".to_d],
        ["0.4256372e5".to_d, "0.307485e1".to_d],
        ["0.4259916e5".to_d, "0.104e-2".to_d],
      ])

      expect(tp.books["alpha.yellow.org:btcusd"][:book][:buy].to_a).to eq([
        ["0.4245432e5".to_d, "0.328781e1".to_d],
        ["0.4241929e5".to_d, "0.263796e1".to_d],
        ["0.4241821e5".to_d, "0.577107e1".to_d],
        ["0.4236536e5".to_d, "0.1301232e2".to_d],
      ])
    end

    it "ignores increments with lower sequence than snapshot sequence" do
      tp.instance_variable_set(:@original_fetch_orderbook, tp.method(:fetch_orderbook))

      def tp.fetch_orderbook(stream, market)
        handle_ob_inc(stream, market, 11, [["0.4251344e5","0.89242e0"]], [])
        handle_ob_inc(stream, market, 12, [["0.4251345e5","0.89242e0"]], [])
        handle_ob_inc(stream, market, 13, [["0.4251346e5","0.89242e0"]], [])
        handle_ob_inc(stream, market, 14, [["0.4250346e5","0.89254e0"]], [["0.4226536e5","0.1301298e2"]])
        @original_fetch_orderbook.call(stream, market)
      end

      tp.ws_connect_public

      expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(14)
      expect(tp.books["alpha.yellow.org:btcusd"][:book][:sell].to_a).to eq([
        ["0.4250346e5".to_d, "0.89254e0".to_d],
        ["0.4251346e5".to_d, "0.89242e0".to_d],
        ["0.4252346e5".to_d, "0.89235e0".to_d],
        ["0.4252598e5".to_d, "0.21941e0".to_d],
        ["0.4256372e5".to_d, "0.307485e1".to_d],
        ["0.4259916e5".to_d, "0.104e-2".to_d],
      ])

      expect(tp.books["alpha.yellow.org:btcusd"][:book][:buy].to_a).to eq([
        ["0.4245432e5".to_d, "0.328781e1".to_d],
        ["0.4241929e5".to_d, "0.263796e1".to_d],
        ["0.4241821e5".to_d, "0.577107e1".to_d],
        ["0.4236536e5".to_d, "0.1301232e2".to_d],
        ["0.4226536e5".to_d, "0.1301298e2".to_d],
      ])    end

    it "fails if a gap in sequences is detectedl during initialization pahse" do
      EM.run do
        tp.instance_variable_set(:@original_fetch_orderbook, tp.method(:fetch_orderbook))

        def tp.fetch_orderbook(stream, market)
          handle_ob_inc(stream, market, 14, [["0.4250346e5","0.89254e0"]], [["0.4226536e5","0.1301298e2"]])
          @original_fetch_orderbook.call(stream, market)
        end

        tp.ws_connect_public

        expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(nil)
        expect(tp.books["alpha.yellow.org:btcusd"][:book]).to eq(nil)
        EM.next_tick { EM.stop }
      end
    end

    it "applies increments after the orderbook was initialized" do
      tp.ws_connect_public

      tp.handle_ob_inc("alpha.yellow.org", "btcusd", 13, [["0.4251346e5","0.89242e0"]], [])
      expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(13)

      tp.handle_ob_inc("alpha.yellow.org", "btcusd", 14, [["0.4250346e5","0.89254e0"]], [["0.4226536e5","0.1301298e2"]])
      expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(14)
      expect(tp.books["alpha.yellow.org:btcusd"][:book][:sell].to_a).to eq([
        ["0.4250346e5".to_d, "0.89254e0".to_d],
        ["0.4251346e5".to_d, "0.89242e0".to_d],
        ["0.4252346e5".to_d, "0.89235e0".to_d],
        ["0.4252598e5".to_d, "0.21941e0".to_d],
        ["0.4256372e5".to_d, "0.307485e1".to_d],
        ["0.4259916e5".to_d, "0.104e-2".to_d],
      ])

      expect(tp.books["alpha.yellow.org:btcusd"][:book][:buy].to_a).to eq([
        ["0.4245432e5".to_d, "0.328781e1".to_d],
        ["0.4241929e5".to_d, "0.263796e1".to_d],
        ["0.4241821e5".to_d, "0.577107e1".to_d],
        ["0.4236536e5".to_d, "0.1301232e2".to_d],
        ["0.4226536e5".to_d, "0.1301298e2".to_d],
      ])
    end

    it "re-init the orderbook if an increment sequence received after init doesn't match the following number" do
      EM.run do
        tp.ws_connect_public
        EM.next_tick do
          tp.handle_ob_inc("alpha.yellow.org", "btcusd", 13, [["0.4251346e5","0.89242e0"]], [])
          expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(13)

          expect {
            tp.handle_ob_inc("alpha.yellow.org", "btcusd", 15, [["0.4250346e5","0.89254e0"]], [["0.4226536e5","0.1301298e2"]])
          }.to raise_error(::Arke::Exchange::Tradepoint::OrderbookSequenceError)

          expect(tp.books["alpha.yellow.org:btcusd"][:sequence]).to eq(nil)
          expect(tp.books["alpha.yellow.org:btcusd"][:book]).to eq(nil)
          EM.next_tick { EM.stop }
        end
      end
    end

  end
end
