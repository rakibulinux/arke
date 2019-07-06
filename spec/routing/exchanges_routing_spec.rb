require "rails_helper"

RSpec.describe ExchangesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/exchanges").to route_to("exchanges#index")
    end

    it "routes to #show" do
      expect(:get => "/exchanges/1").to route_to("exchanges#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/exchanges").to route_to("exchanges#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/exchanges/1").to route_to("exchanges#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/exchanges/1").to route_to("exchanges#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/exchanges/1").to route_to("exchanges#destroy", :id => "1")
    end
  end
end
