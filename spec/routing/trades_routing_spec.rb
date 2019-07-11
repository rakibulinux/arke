require "rails_helper"

RSpec.describe Api::V1::TradesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/api/v1/trades").to route_to("api/v1/trades#index")
    end
  end
end
