require "rails_helper"

RSpec.describe Api::V1::BalancesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/api/v1/balances").to route_to("api/v1/balances#index")
    end
  end
end
