# frozen_string_literal: true

describe Arke::Fx::Fixer do
  let(:config) do
    {
      "currency_from" => "USD",
      "currency_to"   => "ZAR",
      "api_key"       => "abcdefghijklmnopqrstuvwxyz123456"
    }
  end

  let(:fx) do
    ::Arke::Fx::Fixer.new(config)
  end

  context "valid credentials" do
    before(:each) do
      stub_request(:get, "https://data.fixer.io/api/latest?access_key=abcdefghijklmnopqrstuvwxyz123456&base=USD&symbols=ZAR")
        .to_return(
          status:  200,
          body:    {
            "success":   true,
            "timestamp": 1_577_003_046,
            "base":      "USD",
            "date":      "2019-12-22",
            "rates":     {
              "ZAR": 14.293704
            }
          }.to_json,
          headers: {"content-type" => "application/json; Charset=UTF-8"}
        )
    end

    it "fetches the forex rate from fixer" do
      EM.synchrony do
        fx.start
        expect(fx.rate).to eq(14.293704)
        EM.stop
      end
    end
  end

  context "invalid currency" do
    let(:config) do
      {
        "currency_from" => "USD",
        "currency_to"   => "ZART",
        "api_key"       => "abcdefghijklmnopqrstuvwxyz123456"
      }
    end

    before(:each) do
      stub_request(:get, "https://data.fixer.io/api/latest?access_key=abcdefghijklmnopqrstuvwxyz123456&base=USD&symbols=ZART")
        .to_return(
          status:  200,
          body:    {
            "success": false,
            "error":   {
              "code": 202,
              "type": "invalid_currency_codes",
              "info": "You have provided one or more invalid Currency Codes. [Required format: currencies=EUR,USD,GBP,...]"
            }
          }
          .to_json,
          headers: {"content-type" => "application/json; Charset=UTF-8"}
        )
    end

    it "fetches the forex rate from fixer" do
      EM.synchrony do
        fx.start
        expect(fx.rate).to eq(nil)
        EM.stop
      end
    end
  end
end
