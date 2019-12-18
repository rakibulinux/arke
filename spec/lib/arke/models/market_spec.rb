# frozen_string_literal: true

describe Arke::Market do
  let(:market) { Arke::Market.new(market_id, account, mode) }
  let(:market_id) { "ABCXYZ" }
  let(:exchange_config) do
    {
      "driver" => "base",
      "host"   => "http://www.example.com",
    }
  end
  let(:account) { Arke::Exchange::Base.new(exchange_config) }
  let(:mode) { 0x0 }
  let(:market_config) do
    {
      "id"               => "ABCXYZ",
      "base_unit"        => "abc",
      "quote_unit"       => "xyz",
      "min_price"        => 100.0,
      "max_price"        => 100_000.0,
      "min_amount"       => 0.0005,
      "amount_precision" => 6,
      "price_precision"  => 2
    }
  end
  before(:each) do
    allow(account).to receive(:market_config).and_return(market_config)
  end

  context "valid params" do
    it "doesn't raise" do
      expect { market.check_config }.to_not raise_error(StandardError)
    end
  end

  context "missing market_id" do
    let(:market_id) { nil }
    it "raises error" do
      expect { market.check_config }.to raise_error(StandardError, "missing market_id")
    end
  end

  context "FORCE_MARKET_LOWERCASE flag set" do
    let(:mode) { Arke::Helpers::Flags::FORCE_MARKET_LOWERCASE }

    context "market is lower case" do
      let(:market_id) { "abcxyz" }

      it "doesn't raises" do
        expect { market.check_config }.to_not raise_error(StandardError)
      end
    end

    context "market is upper case" do
      it "raises an error" do
        expect { market.check_config }.to raise_error(StandardError, "market id must be lowercase for this exchange")
      end
    end
  end

  context "missing amount_precision from market configuration" do
    let(:market_config) do
      {
        "id"               => "ABCXYZ",
        "base_unit"        => "abc",
        "quote_unit"       => "xyz",
        "min_price"        => 100.0,
        "max_price"        => 100_000.0,
        "min_amount"       => 0.0005,
        "amount_precision" => nil,
        "price_precision"  => 2
      }
    end

    context "READ ONLY mode" do
      let(:mode) { 0x0 }
      it "doesn't raises" do
        expect { market.check_config }.to_not raise_error(StandardError)
      end
    end

    context "WRITE mode" do
      let(:mode) { Arke::Helpers::Flags::WRITE }
      it "raises an error" do
        expect { market.check_config }.to raise_error(StandardError, "amount_precision is missing in market ABCXYZ configuration")
      end
    end
  end

  context "missing price_precision from market configuration" do
    let(:market_config) do
      {
        "id"               => "ABCXYZ",
        "base_unit"        => "abc",
        "quote_unit"       => "xyz",
        "min_price"        => 100.0,
        "max_price"        => 100_000.0,
        "min_amount"       => 0.0005,
        "amount_precision" => 6,
        "price_precision"  => nil
      }
    end

    context "READ ONLY mode" do
      let(:mode) { 0x0 }
      it "doesn't raises" do
        expect { market.check_config }.to_not raise_error(StandardError)
      end
    end

    context "WRITE mode" do
      let(:mode) { Arke::Helpers::Flags::WRITE }
      it "raises an error" do
        expect { market.check_config }.to raise_error(StandardError, "price_precision is missing in market ABCXYZ configuration")
      end
    end
  end

  context "missing min_amount from market configuration" do
    let(:market_config) do
      {
        "id"               => "ABCXYZ",
        "base_unit"        => "abc",
        "quote_unit"       => "xyz",
        "min_price"        => 100.0,
        "max_price"        => 100_000.0,
        "min_amount"       => nil,
        "amount_precision" => 6,
        "price_precision"  => 2
      }
    end

    context "READ ONLY mode" do
      let(:mode) { 0x0 }
      it "doesn't raises" do
        expect { market.check_config }.to_not raise_error(StandardError)
      end
    end

    context "WRITE mode" do
      let(:mode) { Arke::Helpers::Flags::WRITE }
      it "raises an error" do
        expect { market.check_config }.to raise_error(StandardError, "min_amount is missing in market ABCXYZ configuration")
      end
    end
  end
end
