require "em-websocket"

describe Arke::Exchange::OpendaxV4 do
  let(:logger) do
    Logger.new(STDERR)
  end

  let(:timeout) { 0.5 }

  let(:market_id) { "ethusd" }

  let!(:default_opendax_v4) {
    Arke::Exchange::OpendaxV4.new(
      "ws"          => "ws://localhost:5050",
      "key"         => "4576fdf6bde1fe670b17ee667d4da85ca3a4383219757a977dfa8cfe3b5c89ee",
      "secret"      => "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw",
      "go_true_url" => "http://localhost:9999"
    )
  }

  def new_odax(port)
    Arke::Exchange::OpendaxV4.new(
      "ws"      => "ws://localhost:#{port}",
      "key"     => "4576fdf6bde1fe670b17ee667d4da85ca3a4383219757a977dfa8cfe3b5c89ee",
      "secret"  => "OwpadzSYOSkzweoJkjPrFeVgjOwOuxVHk8FXIlffdWw",
      "timeout" => timeout
    )
  end

  # Start websocket server connection
  def ws_server(opts={})
    port = rand(8000..10_000)
    EM::WebSocket.run({host: "localhost", port: port}.merge(opts)) {|socket|
      socket.onopen {|handshake|}
      socket.onmessage do |msg|
        yield(socket, msg) if block_given?
      end
      socket.onerror do |e|
        logger.error "ws server error: #{e.message}"
      end
    }
    port
  end

  before(:all) do
    ENV['RUBY_ENV'] = "test"
  end

  context "timeout" do
    let(:timeout) { 0.01 }

    before do
      Arke::Exchange::OpendaxV4.any_instance.stub(:generate_jwt).and_return "jwt_token"
    end

    it "cancels request and returns nil when timeout is reached" do
      EM.synchrony do
        EM.add_timer(2) { raise "timeout" }

        port = ws_server do |socket, msg|
          logger.info "ws server received: #{msg}"
          case msg
          when '[1,1,"list_orders",["btcusd",0,0,"wait"]]'
            logger.info "scheduling the response"
            EM::Timer.new(timeout * 10) do
              logger.info "sending the response"
              socket.send '[2,1,"list_orders",[]]'
            end
          else
            raise "unexpected message: #{msg}"
          end
        end

        odax = new_odax(port)
        odax.ws_connect_private
        orders = odax.fetch_openorders("btcusd")
        expect(orders).to be_nil
        EM.stop
      end
    end
  end

  context "fetch_openorders" do
    before do
      Arke::Exchange::OpendaxV4.any_instance.stub(:generate_jwt).and_return "jwt_token"
    end

    it do
      EM.synchrony do
        EM.add_timer(1) { raise "timeout" }

        port = ws_server do |socket, msg|
          logger.info "ws server received: #{msg}"
          case msg
          when '[1,1,"list_orders",["btcusd",0,0,"wait"]]'
            socket.send '[2,1,"list_orders",[["btcusd",97,"6dcc2c8e-c295-11ea-b7ad-1831bf9834b0","sell","w","l","9120","0","0.25","0.25","0",0,1594386563,"0.25","0.25"]]]'
          else
            raise "unexpected message: #{msg}"
          end
        end

        odax = new_odax(port)
        odax.ws_connect_private
        orders = odax.fetch_openorders("btcusd")
        expect(orders.empty?).to eq(false)
        EM.stop
      end
    end
  end

  context "#cancel_all_orders" do
    before do
      Arke::Exchange::OpendaxV4.any_instance.stub(:generate_jwt).and_return "jwt_token"
    end

    let(:order) { Arke::Order.new("ethusd", 1, 1, :buy, "limit", 12) }
    let(:order_second) { Arke::Order.new("ethusd", 1, 1, :sell, "limit", 13) }

    let(:markets) {
      [
        ["ethusd","spot","eth","usdt","enabled",101,4,4,"0.0001","2000","0.0001"],
        ["ethfau","spot","eth","fau","enabled",103,4,4,"10","6000","5"],
      ]
    }

    it "cancel all open orders orders" do
      EM.synchrony do
        EM.add_timer(1) { raise "timeout" }
        port = ws_server do |_, msg|
          logger.info "ws server received: #{msg}"
        end

        odax = new_odax(port)
        odax.ws_connect_private

        odax.instance_variable_set(:@markets, markets)

        # Add some orders
        market = Arke::Market.new("ethusd", odax)
        market.add_order(order)
        market.add_order(order_second)
        odax.cancel_all_orders("ethusd")

        expect(market.open_orders[:buy].length).to eq(1)
        expect(market.open_orders[:sell].length).to eq(1)

        EM.stop
      end
    end

  end

  context "#stop_order" do
    before do
      Arke::Exchange::OpendaxV4.any_instance.stub(:generate_jwt).and_return "jwt_token"
    end

    let(:order) { Arke::Order.new("ethusd", 1, 1, :buy, "limit", 12) }

    let(:markets) {
      [
        ["ethusd","spot","eth","usdt","enabled",101,4,4,"0.0001","2000","0.0001"],
        ["ethfau","spot","eth","fau","enabled",103,4,4,"10","6000","5"],
      ]
    }

    it "stop order" do
      EM.synchrony do
        EM.add_timer(1) { raise "timeout" }
        port = ws_server do |_, msg|
          logger.info "ws server received: #{msg}"
        end

        odax = new_odax(port)
        odax.ws_connect_private

        odax.instance_variable_set(:@markets, markets)

        market = Arke::Market.new("ethusd", odax)
        market.add_order(order)
        odax.stop_order(order)

        expect(market.open_orders[:buy].length).to eq(1)
        expect(market.open_orders[:sell].length).to eq(0)

        EM.stop
      end
    end
  end

  context "#create_order" do
    before do
      Arke::Exchange::OpendaxV4.any_instance.stub(:generate_jwt).and_return "jwt_token"
    end

    let(:order) { Arke::Order.new("ethusd", 1, 1, :buy, "limit", 12) }

    let(:markets) {
      [
        ["ethusd","spot","eth","usdt","enabled",101,4,4,"0.0001","2000","0.0001"],
        ["ethfau","spot","eth","fau","enabled",103,4,4,"10","6000","5"],
      ]
    }

    it "create order" do
      EM.synchrony do
        EM.add_timer(1) { raise "timeout" }
        port = ws_server do |_, msg|
          logger.info "ws server received: #{msg}"
        end

        odax = new_odax(port)
        odax.ws_connect_private

        odax.instance_variable_set(:@markets, markets)
        odax.create_order(order)

        EM.stop
      end
    end
  end

  context "#ws_handle_public_event" do
    let(:snapshot) do
      [
          "btcusdt",
          6111,
          [
            ["252.32", "0.2"],
            ["252.92", "0.90403"],
            ["253.08", "0.73563"],
          ],
          [
            ["249.16", "0.20603"],
            ["248.69", "0.09944"],
            ["248.66", "0.05057"],
          ]
      ]
    end

    context "obs" do
      it 'should create orderbook with snapshot' do
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_SNAPSHOT, snapshot)

        expect(default_opendax_v4.update_orderbook("btcusdt")[:sell].to_hash).to eq(
          249.16.to_d => 0.20603.to_d,
          248.69.to_d => 0.09944.to_d,
          248.66.to_d => 0.05057.to_d
        )

        expect(default_opendax_v4.update_orderbook("btcusdt")[:buy].to_hash).to eq(
          252.32.to_d => 0.2.to_d,
          252.92.to_d => 0.90403.to_d,
          253.08.to_d => 0.73563.to_d
        )
      end
    end

    context "obi" do
      it "updates an existing price point" do
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_SNAPSHOT, snapshot)
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_INCREMENT, ["btcusdt", 6112, [], [["252.32", "0.1"]]])
        expect(default_opendax_v4.update_orderbook("btcusdt")[:sell].to_hash).to eq(
          249.16.to_d => 0.20603.to_d,
          248.69.to_d => 0.09944.to_d,
          248.66.to_d => 0.05057.to_d
        )
        expect(default_opendax_v4.update_orderbook("btcusdt")[:buy].to_hash).to eq(
          252.32.to_d => 0.1.to_d,
          252.92.to_d => 0.90403.to_d,
          253.08.to_d => 0.73563.to_d
        )
      end

      it "deletes an existing price point" do
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_SNAPSHOT, snapshot)
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_INCREMENT, ["btcusdt", 6112, [], [["252.32", "0.0"]]])
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_INCREMENT, ["btcusdt", 6113, [["248.69", "0.0"]], []])

        expect(default_opendax_v4.update_orderbook("btcusdt")[:sell].to_hash).to eq(
          249.16.to_d => 0.20603.to_d,
          248.66.to_d => 0.05057.to_d
        )

        expect(default_opendax_v4.update_orderbook("btcusdt")[:buy].to_hash).to eq(
          252.92.to_d => 0.90403.to_d,
          253.08.to_d => 0.73563.to_d
        )
      end

      it "deletes an existing price point (again)" do
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_SNAPSHOT, snapshot)
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_INCREMENT, ["btcusdt", 6112, [], [["252.32", ""]]])
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_INCREMENT, ["btcusdt", 6113, [["248.69", ""]], []])

        expect(default_opendax_v4.update_orderbook("btcusdt")[:sell].to_hash).to eq(
          249.16.to_d => 0.20603.to_d,
          248.66.to_d => 0.05057.to_d
        )
        expect(default_opendax_v4.update_orderbook("btcusdt")[:buy].to_hash).to eq(
          252.92.to_d => 0.90403.to_d,
          253.08.to_d => 0.73563.to_d
        )
      end

      it "disconnects websocket if it detects a sequence out of order" do
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_SNAPSHOT, snapshot)
        ws = double(close: true)
        default_opendax_v4.instance_variable_set(:@ws, ws)
        expect(ws).to receive(:close)
        default_opendax_v4.ws_handle_public_event(Arke::Exchange::OpendaxV4::EVENT_ORDERBOOK_INCREMENT, ["btcusdt", 6113, [], [["252.32", ""]]])
      end
    end

    context "markets" do
      let(:markets) {
        [
          ["btcusdt","spot","btc","usdt","enabled",100,5,2,"0.0001","0","0.0001"],
          ["ethbtc","spot","eth","btc","enabled",103,5,3,"0.0001","0","0.001"],
          ["ethusdt","spot","eth","usdt","enabled",101,4,4,"0.0001","2000","0.0001"],
        ]
      }

      it "should set instance variable" do
        default_opendax_v4.ws_handle_public_event("markets", markets)

        expect(default_opendax_v4.instance_variable_get(:@markets)).to eq markets
      end
    end
  end

  context "ws_handle_private_event" do
    context "event balance update" do
      let(:balances_event) do
        [
          ["btc", 0.998, 0.002],
          ["eth", 1000000000, 0],
        ]
      end

      it 'should update balances' do
        default_opendax_v4.ws_handle_private_event(Arke::Exchange::OpendaxV4::EVENT_BALANCE_UPDATE, balances_event)

        expect(default_opendax_v4.fetch_balances).to eq(
          [
            {
              "currency" => "btc",
              "free"     => 0.996,
              "locked"   => 0.002,
              "total"    => 0.998,
            },
            {
              "currency" => "eth",
              "free"     => 1_000_000_000,
              "locked"   => 0,
              "total"    => 1_000_000_000,
            },
          ]
        )

        expect(default_opendax_v4.balance("trst")).to be_nil
      end
    end

    context "event trade" do
      let(:trade_args) {
        ["btcusdt",9,"0.1","0.1","0.01",23,"2f15ccd9-0708-43c8-9451-60bb98b620f1","sell","sell","0.00002","usdt",1639470508]
      }
      it 'should notify about trade event' do
        default_opendax_v4.ws_handle_private_event(Arke::Exchange::OpendaxV4::EVENT_TRADE, trade_args)
      end
    end

    context "order event" do
      let(:order_args) {
        ["btcusdt",18,"3b0474d7-6219-445b-a614-7208f9360135","buy","w","l","0.002","0","0","0.001","0.001",0,1639469280,"0.002","0.002"]
      }

      it 'should notify about order creation' do
        default_opendax_v4.ws_handle_private_event(Arke::Exchange::OpendaxV4::EVENT_ORDER_CREATE, order_args)
      end
    end
  end

  context "market_config" do
    context "with empty markets" do
      it "returns market configuration" do
       expect { default_opendax_v4.market_config("ETHUSDT") }.to raise_error(RuntimeError)
      end
    end

    context "with markets"  do
      let(:markets) {
        [
          ["ethfau","spot","eth","fau","enabled",103,4,4,"10","6000","5"],
          ["btcusdt","spot","btc","usdt","enabled",100,5,2,"0.0001","0","0.0001"],
          ["ethbtc","spot","eth","btc","enabled",103,5,3,"0.0001","0","0.001"],
          ["ethusdt","spot","eth","usdt","enabled",101,4,4,"0.0001","2000","0.0001"],
          ["tokbtc","spot","tok","btc","enabled",102,4,4,"0.0001","0","0.0001"],
          ["tokusdt","spot","tok","usdt","enabled",102,4,4,"0.0001","0","0.0001"]
        ]
      }

      before do
        default_opendax_v4.instance_variable_set(:@markets, markets)
      end

      it "returns market configuration" do
        expect(default_opendax_v4.market_config("ethusdt")).to eq(
          "id"               => "ethusdt",
          "base_unit"        => "eth",
          "quote_unit"       => "usdt",
          "min_price"        => 0.0001,
          "max_price"        => 2000.0,
          "min_amount"       => 0.0001,
          "amount_precision" => 4.0,
          "price_precision"  => 4.0
        )
      end
    end
  end

  context "private functions" do
    context "generate signature" do
      before do
        default_opendax_v4.instance_variable_set(:@api_key, "8cc4fcb9a87bbe5733c2402c438c8397d6a23dc7f262e9d3abd9a57a990404c5")
      end

      it "should generate signature" do
        hash = default_opendax_v4.send(:sign_eth_message, "ec041668-37aa-4497-94e6-892dcdb0ef24")
        expect(Base64.encode64(hash)).to eq("a8hR2tLR7DOnE6mvFo4eHRvc5s1SOaKUKy6gAwTlBms=\n")
        signature = default_opendax_v4.send(:generate_signature, hash)
        expect(signature).to eq("0xb5d0fb6dcdc6ccfe2f1c93a06efba4242f5641c11bf36d3d8788af99c175d06600e82cfc6c03503bf71b9eb9fcb421b124b219a4969149e35e9a73cbafe457af1b")
      end
    end
  end

  context "generate_jwt" do
    context "with error" do
      context "api_key doesnt exist" do
        before do
          default_opendax_v4.instance_variable_set(:@api_key, nil)
        end

        it "should raise an error" do
          expect { default_opendax_v4.generate_jwt }.to raise_error(RuntimeError, "There is no api key")
        end
      end

      context "sign_challange address is incorrect" do
        before do
          default_opendax_v4.instance_variable_set(:@api_key, "8cc4fcb9a87bbe5733c2402c438c8397d6a23dc7f262e9d3abd9a57a990404c5")
        end

        before do
          stub_request(:post, 'http://localhost:9999/api/v1/auth/sign_challenge')
            .with(headers: {"apikey" => "", "Content-Type" => "application/json"},
                  body: {"algorithm" => "ETH", "key" => "0xED29f5CAA68D7190fea29a84c6740dBF0FcFBd70"})
            .to_return(
              status:  422,
              body: {code: 422, msg: "Invalid address"}.to_json,
              headers: {}
            )
        end

        it "should raise an error" do
          expect {default_opendax_v4.generate_jwt}.to raise_error(RuntimeError)
        end
      end

      context "invalid signature" do
        before do
          default_opendax_v4.instance_variable_set(:@api_key, "8cc4fcb9a87bbe5733c2402c438c8397d6a23dc7f262e9d3abd9a57a990404c5")
        end

        before do
          stub_request(:post, 'http://localhost:9999/api/v1/auth/sign_challenge')
            .with(headers: {"apikey" => "", "Content-Type" => "application/json"},
                  body: {"algorithm" => "ETH", "key" => "0xED29f5CAA68D7190fea29a84c6740dBF0FcFBd70"})
            .to_return(
              status:  200,
              body: { challenge_token: "ec041668-37aa-4497-94e6-892dcdb0ef24"}.to_json,
              headers: {}
            )

          stub_request(:post, 'http://localhost:9999/api/v1/auth/asymmetric_login')
            .with(headers: {"apikey" => "", "Content-Type" => "application/json"},
                  body: {"key" => "0xED29f5CAA68D7190fea29a84c6740dBF0FcFBd70", "challenge_token_signature" => "0xb5d0fb6dcdc6ccfe2f1c93a06efba4242f5641c11bf36d3d8788af99c175d06600e82cfc6c03503bf71b9eb9fcb421b124b219a4969149e35e9a73cbafe457af1b"})
            .to_return(
              status:  422,
              body: {code: 422, msg: "Signature verification failed:Provided signature does not match with Key"}.to_json,
              headers: {}
            )
        end

        it "should raise an error" do
          expect {default_opendax_v4.generate_jwt}.to raise_error(RuntimeError)
        end
      end
    end

    context "without error" do
      before do
        default_opendax_v4.instance_variable_set(:@api_key, "8cc4fcb9a87bbe5733c2402c438c8397d6a23dc7f262e9d3abd9a57a990404c5")
      end

      before do
        stub_request(:post, 'http://localhost:9999/api/v1/auth/sign_challenge')
          .with(headers: {"apikey" => "", "Content-Type" => "application/json"},
                body: {"algorithm" => "ETH", "key" => "0xED29f5CAA68D7190fea29a84c6740dBF0FcFBd70"})
          .to_return(
            status:  200,
            body: { challenge_token: "ec041668-37aa-4497-94e6-892dcdb0ef24"}.to_json,
            headers: {}
          )

        stub_request(:post, 'http://localhost:9999/api/v1/auth/asymmetric_login')
          .with(headers: {"apikey" => "", "Content-Type" => "application/json"},
                body: {"key" => "0xED29f5CAA68D7190fea29a84c6740dBF0FcFBd70", "challenge_token_signature" => "0xb5d0fb6dcdc6ccfe2f1c93a06efba4242f5641c11bf36d3d8788af99c175d06600e82cfc6c03503bf71b9eb9fcb421b124b219a4969149e35e9a73cbafe457af1b"})
          .to_return(
            status:  200,
            body: {access_token: "jwt_token"}.to_json,
            headers: {}
          )
      end

      it "should create jwt token" do
        expect(default_opendax_v4.generate_jwt).to eq "jwt_token"
      end
    end
  end
end
