require "rails_helper"

RSpec.describe Api::V1::TickersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/api/v1/tickers").to route_to("api/v1/tickers#index")
    end
  end
end
