require "rails_helper"

RSpec.describe Api::V1::StrategiesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/api/v1/strategies").to route_to("api/v1/strategies#index")
    end
  end
end
