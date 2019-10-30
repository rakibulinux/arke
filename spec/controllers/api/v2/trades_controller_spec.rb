require 'rails_helper'

RSpec.describe Api::V2::Public::Markets::TradesController, type: :controller do
  describe 'GET #index' do
    let(:trades) do
      [{"name"=>"trades",
      "tags"=>nil,
      "values"=>
      [{"time"=>"2019-10-25T11:48:30.105Z",
      "amount"=>0.060001,
      "exchange"=>"binance",
      "id"=>176027361,
      "market"=>"btcusdt",
      "price"=>7595.66,
      "taker_type"=>"sell",
      "total"=>455.74719566},
      {"time"=>"2019-10-25T11:48:30.084Z",
      "amount"=>0.003576,
      "exchange"=>"binance",
      "id"=>176027359,
      "market"=>"btcusdt",
      "price"=>7596.96,
      "taker_type"=>"buy",
      "total"=>27.16672896}
    ]}]
    end

    let(:trade_keys) {
      ["amount", "id", "market", "price", "taker_type", "total", "created_at"]
    }
      

    context 'invalid parameters' do
      it 'returns error when "limit" > 1000' do
        get :index, params: { market: 'btcusdt', limit: 1001}
        result = JSON.parse(response.body)

        expect(result["errors"]).to eq("public.k_line.invalid_limit")
        expect(response).to_not be_successful
        expect(response.status).to eq(422) 
      end

      it 'returns error when "limit" < 0' do
        get :index, params: { market: 'btcusdt', limit: -1}
        result = JSON.parse(response.body)
        

        expect(result["errors"]).to eq("public.k_line.invalid_limit")
        expect(response).to_not be_successful
        expect(response.status).to eq(422)  
      end
    end

    context 'valid parameters' do
      before do
        allow_any_instance_of(InfluxDB::Client).to receive(:query).and_return(trades)
      end

      it 'returns 1 trade' do
        get :index, params: { market: 'btcusdt', limit: 1}
       
        result = JSON.parse(response.body)
        expect(result.first.keys).to contain_exactly(*trade_keys)
        expect(response).to be_successful
        expect(result.count).to eq 1
      end

      it 'returns 2 trades' do
        get :index, params: { market: 'btcusdt', limit: 2}

        result = JSON.parse(response.body)
        expect(result.first.keys).to contain_exactly(*trade_keys)
        expect(response).to be_successful
        expect(result.count).to eq 2
      end
    end

    context 'Nonexistent market' do
      before do
        allow_any_instance_of(InfluxDB::Client).to receive(:query).and_return([])
      end

      it 'returns empty array' do
        get :index, params: { market: 'btcbtc', limit: 1}

        result = JSON.parse(response.body)
        expect(response).to be_successful
        expect(result.count).to eq 0
        expect(result).to eq([])
      end
    end
  end
end
