# frozen_string_literal: true

describe Arke::Helpers::Precision do
  context "value_precision" do
    include Arke::Helpers::Precision

    it "returns the precision from a value" do
      expect(value_precision(0.1)).to eq(1)
      expect(value_precision(0.01)).to eq(2)
      expect(value_precision(0.001)).to eq(3)
      expect(value_precision(0.000001)).to eq(6)
      expect(value_precision(0)).to eq(0)
      expect(value_precision(1)).to eq(0)
      expect(value_precision(2)).to eq(0)
      expect(value_precision(10)).to eq(-1)
      expect(value_precision(100)).to eq(-2)
    end
  end
end
