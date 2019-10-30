require 'rails_helper'

RSpec.describe Api::V2::Public::Markets::KlineController, type: :controller do
  describe 'GET #index' do
    let(:k_lines) do 
      [{"name"=>"candles_1m",
        "tags"=>nil,
        "values"=>
          [{"time"=>1572002280,
          "close"=>7624.71,
          "exchange"=>"binance",
          "high"=>7625.18,
          "low"=>7614.68,
          "market"=>"btcusdt",
          "open"=>7620.22,
          "volume"=>61.432564999999954},
          {"time"=>1572002340,
          "close"=>7618,
          "exchange"=>"binance",
          "high"=>7632.49,
          "low"=>7618,
          "market"=>"btcusdt",
          "open"=>7624.71,
          "volume"=>89.755964}]
      }]
    end


    context 'invalid parameters' do
      it 'returns error when no parameters specified' do
        get :index, params: { market: 'btcusdt'}
        result = JSON.parse(response.body)

        expect(result["errors"]).to eq("public.k_line.invalid_period")
        expect(response).to_not be_successful
        expect(response.status).to eq(422)  
      end

      it 'returns error when time not specified' do
        get :index, params: { market: 'btcusdt', period: 1}
        result = JSON.parse(response.body)

        expect(result["errors"]).to eq("public.k_line.non_integer_time")
        expect(response).to_not be_successful
        expect(response.status).to eq(422)  
      end
    end

    context 'valid parameters' do
      before do
        allow_any_instance_of(InfluxDB::Client).to receive(:query).and_return(k_lines)
      end

      it 'returns 2 arrays from influx' do
        get :index, params: { market: 'btcusdt', period: 1, time_from: 1570017578, time_to: 1572002378}

        result = JSON.parse(response.body)
        expect(response).to be_successful
        expect(result.count).to eq 2
      end
    end

    context 'nonexistent market' do
      before do
        allow_any_instance_of(InfluxDB::Client).to receive(:query).and_return([])
      end

      it 'returns 2 arrays from influx' do
        get :index, params: { market: 'btcbtc', period: 1, time_from: 1570017578, time_to: 1572002278}

        result = JSON.parse(response.body)
        expect(response).to be_successful
        expect(result.count).to eq 0
        expect(result).to eq([])
      end
    end
  end
end
