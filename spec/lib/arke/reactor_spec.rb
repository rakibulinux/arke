require "rails_helper"

describe Arke::Reactor do
  let(:config) { YAML.load_file('spec/support/fixtures/test_config.yaml') }
  let(:reactor) { Arke::Reactor.new(config) }

  it 'inits configuration' do
    expect(reactor.instance_variable_get(:@strategies).length).to be(2)
  end
end
