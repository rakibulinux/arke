require "rails_helper"

RSpec.describe BalancesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/balances").to route_to("balances#index")
    end

    it "routes to #show" do
      expect(:get => "/balances/1").to route_to("balances#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/balances").to route_to("balances#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/balances/1").to route_to("balances#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/balances/1").to route_to("balances#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/balances/1").to route_to("balances#destroy", :id => "1")
    end
  end
end
