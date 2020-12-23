# frozen_string_literal: true

describe Arke::Helpers::PricePoints do
  let(:to_pp) { proc {|price| ::Arke::PricePoint.new(price)} }

  context "price_points constant" do
    include Arke::Helpers::PricePoints
    it "returns price points with constant distance and defined count" do
      expect(price_points(:asks, 100, 5, "constant", 1)).to eq(
        [101, 102, 103, 104, 105].map(&to_pp)
      )
      expect(price_points(:bids, 100, 5, "constant", 1)).to eq(
        [99, 98, 97, 96, 95].map(&to_pp)
      )
    end

    it "returns decimal price points with constant distance and defined count" do
      expect(price_points(:bids, 186.38, 5, "constant", 0.25)).to eq(
        [186.13, 185.88, 185.63, 185.38, 185.13].map(&to_pp)
      )
      expect(price_points(:asks, 186.39, 5, "constant", 0.25)).to eq(
        [186.64, 186.89, 187.14, 187.39, 187.64].map(&to_pp)
      )
    end
  end

  context "price_points linear" do
    include Arke::Helpers::PricePoints
    it "returns price points with constant distance and defined count" do
      expect(price_points(:asks, 100, 5, "linear", 1)).to eq(
        [101, 103, 106, 110, 115].map(&to_pp)
      )
      expect(price_points(:bids, 100, 5, "linear", 1)).to eq(
        [99, 97, 94, 90, 85].map(&to_pp)
      )
    end
    it "returns decimal price points with constant distance and defined count" do
      expect(price_points(:bids, 186.38, 5, "linear", 0.25)).to eq(
        [186.13, 185.63, 184.88, 183.88, 182.63].map(&to_pp)
      )
      expect(price_points(:asks, 186.39, 5, "linear", 0.25)).to eq(
        [186.64, 187.14, 187.89, 188.89, 190.14].map(&to_pp)
      )
    end
  end

  context "invalid params" do
    include Arke::Helpers::PricePoints
    it "raises error" do
      expect { price_points(:asks, nil, 5, "constant", 0.25) }.to_not raise_error(StandardError)
      expect { price_points(:asks, 100, 5, "something", 0.25) }.to raise_error(StandardError)
      expect { price_points(:plop, 100, 5, "constant", 0.25) }.to raise_error(StandardError)
    end
  end
end
