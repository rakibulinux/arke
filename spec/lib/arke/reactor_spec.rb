# frozen_string_literal: true


describe Arke::Reactor do
  let(:config) { YAML.safe_load(file_fixture("test_config.yaml")) }
  let(:reactor) { Arke::Reactor.new(config["strategies"], config["accounts"], false) }

  it "inits configuration" do
    expect(reactor.instance_variable_get(:@strategies).length).to be(2)
  end
end
