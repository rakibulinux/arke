describe Arke::Command do
  let(:config) { YAML.load_file(File.join(__dir__, '../../../config/strategies.yml'))['strategy'] }

  it 'loads configuration' do
    Arke::Command.load_configuration

    expect(Arke::Configuration.get(:strategy)).to eq(config)
  end
end
