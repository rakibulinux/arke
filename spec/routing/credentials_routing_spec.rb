require "rails_helper"

RSpec.describe CredentialsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/credentials").to route_to("credentials#index")
    end

    it "routes to #show" do
      expect(:get => "/credentials/1").to route_to("credentials#show", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/credentials").to route_to("credentials#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/credentials/1").to route_to("credentials#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/credentials/1").to route_to("credentials#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/credentials/1").to route_to("credentials#destroy", :id => "1")
    end
  end
end
