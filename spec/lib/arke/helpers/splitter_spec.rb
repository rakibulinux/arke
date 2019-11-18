# frozen_string_literal: true

describe Arke::Helpers::Splitter do
  context "split_constant" do
    include Arke::Helpers::Splitter
    it "returns price points with constant distance and defined count" do
      expect(split_constant(:asks, 100, 5, step_size: 1)).to eq(
        [101, 102, 103, 104, 105].map(&:to_d)
      )
      expect(split_constant(:bids, 100, 5, step_size: 1)).to eq(
        [99, 98, 97, 96, 95].map(&:to_d)
      )
    end

    it "returns decimal price points with constant distance and defined count" do
      expect(split_constant(:bids, 186.38, 5, step_size: 0.25)).to eq(
        [186.13, 185.88, 185.63, 185.38, 185.13].map(&:to_d)
      )
      expect(split_constant(:asks, 186.39, 5, step_size: 0.25)).to eq(
        [186.64, 186.89, 187.14, 187.39, 187.64].map(&:to_d)
      )
    end
  end

  context "split_constant_pp" do
    include Arke::Helpers::Splitter
    it "returns price points with constant distance and defined count" do
      expect(split_constant_pp(:asks, 100, 5, step_size: 1)).to eq(
        [101, 102, 103, 104, 105].map {|value| ::Arke::PricePoint.new(value) }
      )
      expect(split_constant_pp(:bids, 100, 5, step_size: 1)).to eq(
        [99, 98, 97, 96, 95].map {|value| ::Arke::PricePoint.new(value) }
      )
    end
    it "returns decimal price points with constant distance and defined count" do
      expect(split_constant_pp(:bids, 186.38, 5, step_size: 0.25)).to eq(
        [186.13, 185.88, 185.63, 185.38, 185.13].map {|value| ::Arke::PricePoint.new(value) }
      )
      expect(split_constant_pp(:asks, 186.39, 5, step_size: 0.25)).to eq(
        [186.64, 186.89, 187.14, 187.39, 187.64].map {|value| ::Arke::PricePoint.new(value) }
      )
    end
  end

  context "invalid params" do
    it "raises error" do
      expect { split_constant_pp(:asks, 100, 5) }.to raise_error(StandardError)
      expect { split_constant(:asks, 100, 5) }.to raise_error(StandardError)
    end
  end
end
