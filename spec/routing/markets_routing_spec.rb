require "rails_helper"

RSpec.describe Api::V1::MarketsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/api/v1/markets").to route_to("api/v1/markets#index")
    end
  end
end
