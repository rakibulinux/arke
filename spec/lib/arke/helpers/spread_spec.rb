# frozen_string_literal: true

describe Arke::Helpers::Spread do
  context "apply_spread" do
    include Arke::Helpers::Spread
    it "applies a spread to price depending on order side" do
      expect(apply_spread(:sell, 100, 0.01)).to eq(101)
      expect(apply_spread(:buy,  100, 0.01)).to eq(99)
    end
  end

  context "remove_spread" do
    include Arke::Helpers::Spread
    it "removes a spread to price depending on order side" do
      expect(remove_spread(:sell, 101, 0.01)).to eq(100)
      expect(remove_spread(:buy,   99, 0.01)).to eq(100)
    end
  end
end
