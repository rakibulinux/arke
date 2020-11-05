# frozen_string_literal: true

shared_context "valr public" do
  before(:each) do
    stub_request(:get, "https://api.valr.com/v1/public/currencies")
      .to_return(
        status:  200,
        body:    file_fixture("valr/currencies.json"),
        headers: {
          "Content-Type" => "application/json"
        }
      )

    stub_request(:get, "https://api.valr.com/v1/public/BTCZAR/orderbook")
      .to_return(
        status:  200,
        body:    file_fixture("valr/orderbook.json"),
        headers: {
          "Content-Type" => "application/json"
        }
      )

    stub_request(:get, "https://api.valr.com/v1/public/pairs")
      .to_return(
        status:  200,
        body:    file_fixture("valr/markets.json"),
        headers: {
          "Content-Type" => "application/json"
        }
      )
  end
end

shared_context "valr private" do
  before(:each) do
    allow(valr).to receive(:new_nonce) { 1_576_353_032_322_571 }

    auth_headers = {
      "Accept"         => "application/json",
      "X-VALR-API-KEY" => "abcdef",
    }

    stub_request(:get, "https://api.valr.com/v1/account/balances")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    file_fixture("valr/balances.json"),
        headers: {
          "Content-Type" => "application/json"
        }
      )

    stub_request(:get, "https://api.valr.com/v1/orders/open")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    file_fixture("valr/open_orders.json"),
        headers: {
          "Content-Type" => "application/json"
        }
      )

    stub_request(:get, "https://api.valr.com/v1/wallet/crypto/ETH/deposit/address")
      .with(headers: auth_headers)
      .to_return(
        status:  200,
        body:    '{"currency": "ETH","address": "0xA7Fae2Fd50886b962d46FF4280f595A3982aeAa5"}',
        headers: {
          "Content-Type" => "application/json"
        }
      )

  end
end
