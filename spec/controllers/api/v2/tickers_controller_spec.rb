require 'rails_helper'

RSpec.describe Api::V2::Public::Markets::TickersController, type: :controller do
  describe 'GET #index' do
    let(:tickers) do
      [{"name"=>"tickers",
        "tags"=>nil,
        "values"=>
        [{"time"=>1572220800,
          "avg_price"=>0.0021345,
          "exchange"=>"binance",
          "high"=>0.002135,
          "last"=>0.002135,
          "low"=>0.002134,
          "market"=>"adabnb",
          "open"=>0.002134,
          "price_change_percent"=>0.04686035613871287,
          "volume"=>595},
          {"time"=>1572220800,
          "avg_price"=>4.585250000000003e-06,
          "exchange"=>"binance",
          "high"=>4.6e-06,
          "last"=>4.58e-06,
          "low"=>4.57e-06,
          "market"=>"adabtc",
          "open"=>4.58e-06,
          "price_change_percent"=>0,
          "volume"=>698693}]
        }]
    end

    let(:empty_tickers) {[]}

    let(:ticker_keys) do
      ["low", "high", "open", "last", "volume", "avg_price", "price_change_percent"]
    end

    context 'valid parameters' do
      before do
        allow_any_instance_of(InfluxDB::Client).to receive(:query).and_return(tickers)
      end

      it 'requires tickers with parameters' do
        get :index, params: { market: 'btcusdt'}

        result = JSON.parse(response.body)
        expect(result['adabnb']['at']).not_to be_nil
        expect(result['adabnb']['ticker'].keys).to contain_exactly(*ticker_keys) 
        expect(response).to be_successful
        expect(result.count).to eq 2
      end

      it 'requires tickers without parameters' do
        get :index

        result = JSON.parse(response.body)
        expect(result['adabnb']['at']).not_to be_nil
        expect(result['adabnb']['ticker'].keys).to contain_exactly(*ticker_keys) 
        expect(response).to be_successful
        expect(result.count).to eq 2
      end
    end

    context 'empty db' do

      before do
        allow_any_instance_of(InfluxDB::Client).to receive(:query).and_return(empty_tickers)
      end

      it 'requires tickers without parameters' do
        get :index

        result = JSON.parse(response.body)
        expect(response).to be_successful
        expect(result.count).to eq 0
      end
    end
  end
end
