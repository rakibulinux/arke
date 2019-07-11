require "rails_helper"

RSpec.describe Api::V1::ExchangesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/api/v1/exchanges").to route_to("api/v1/exchanges#index")
    end
  end
end
