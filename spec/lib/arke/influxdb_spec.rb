require "rails_helper"

describe Arke::InfluxDB do
  let(:client) { Arke::InfluxDB.client }
  it "creates InfluxDB::Client" do
    expect(client.is_a?(InfluxDB::Client))
  end

  it "overrides defaults values" do
    Arke::InfluxDB.instance_variable_set(:@client, nil) 
    new_client = Arke::InfluxDB.client(port: 8888)

    expect(new_client.is_a?(InfluxDB::Client))
    expect(new_client.config.port).to eq(8888)
  end
end
