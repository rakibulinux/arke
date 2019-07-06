require 'rails_helper'

RSpec.describe "Balances", type: :request do
  describe "GET /balances" do
    it "works! (now write some real specs)" do
      get balances_path
      expect(response).to have_http_status(200)
    end
  end
end
