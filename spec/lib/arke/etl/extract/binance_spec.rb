# frozen_string_literal: true

describe Arke::ETL::Extract::Binance do
  let(:config) { {} }
  let(:extract) do
    Arke::ETL::Extract::Binance.new(config)
  end

  context "default configuration" do
    it "configures defaults" do
      expect(extract.instance_variable_get(:@config)).to eq(
        "id"     => "extract-binance",
        "driver" => "binance",
        "listen" => []
      )
    end
  end

  context "custom configuration" do
    let(:config) do
      {
        "listen" => [
          "public_trades"
        ]
      }
    end

    it "merges default and custom config" do
      expect(extract.instance_variable_get(:@config)).to eq(
        "id"     => "extract-binance",
        "driver" => "binance",
        "listen" => [
          "public_trades"
        ]
      )
      cb = double()
      expect(cb).to_not receive(:call)
      extract.mount(&cb.method(:call))
    end
  end
end
