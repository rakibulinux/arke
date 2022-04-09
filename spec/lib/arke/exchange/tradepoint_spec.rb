describe Arke::Exchange::Tradepoint do
  let(:tradepoint) {
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
    end

    it do
      tradepoint.apply_flags(::Arke::Helpers::Flags::LISTEN_PUBLIC_ORDERBOOK)
      tradepoint.ws_connect_public
      
    end
  
  end

end
