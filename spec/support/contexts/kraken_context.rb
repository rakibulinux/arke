# frozen_string_literal: true

shared_context "mocked kraken" do
  before(:each) do
    stub_request(:get, "https://api.kraken.com/0/public/AssetPairs")
      .to_return(
        status:  200,
        body:    file_fixture("kraken-assets.json").read,
        headers: {
          "content-type" => "application/json; charset=utf-8"
        }
      )
  end
end
