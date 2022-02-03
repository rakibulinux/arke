# -*- encoding : ascii-8bit -*-

describe Arke::Ethereum::PrivateKey do

  it "test encode" do
    expect(Arke::Ethereum::PrivateKey.new(0).encode(:decimal)).to eq(0)
    expect(Arke::Ethereum::PrivateKey.new(0).encode(:bin_compressed)).to eq(("\x00"*32+"\x01"))
    expect(Arke::Ethereum::PrivateKey.new(0).encode(:hex_compressed)).to eq(("00"*32+"01"))
    expect(Arke::Ethereum::PrivateKey.new(0).encode(:wif_compressed, 100)).to eq('ajCmMoA6v3tMAz296GzcWga3k4ojLQpk7j2iaZzax6qHCUUzVzJq')
  end

  it "test decode" do
    expect(Arke::Ethereum::PrivateKey.new(0).decode(:decimal)).to eq(0)
    expect(Arke::Ethereum::PrivateKey.new("\x00"*32+"\x01").decode(:bin_compressed)).to eq(0)
    expect(Arke::Ethereum::PrivateKey.new("00"*32+"01").decode(:hex_compressed)).to eq(0)
    expect(Arke::Ethereum::PrivateKey.new('ajCmMoA6v3tMAz296GzcWga3k4ojLQpk7j2iaZzax6qHCUUzVzJq').decode(:wif_compressed)).to eq(0)
  end

  it "test format" do
    expect(Arke::Ethereum::PrivateKey.new(1).format).to eq(:decimal)
    expect(Arke::Ethereum::PrivateKey.new('ff'*32).format).to eq(:hex)
  end

  it "test to_pubkey" do
    expect(Arke::Ethereum::PrivateKey.new("\x01"*32).to_pubkey).to eq("\x04\x1b\x84\xc5V{\x12d@\x99]>\xd5\xaa\xba\x05e\xd7\x1e\x184`H\x19\xff\x9c\x17\xf5\xe9\xd5\xdd\x07\x8fp\xbe\xaf\x8fX\x8bT\x15\x07\xfe\xd6\xa6B\xc5\xabB\xdf\xdf\x81 \xa7\xf69\xdeQ\"\xd4zi\xa8\xe8\xd1")
    expect(Arke::Ethereum::PrivateKey.new("01"*32).to_pubkey).to eq('041b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f70beaf8f588b541507fed6a642c5ab42dfdf8120a7f639de5122d47a69a8e8d1')
    expect(Arke::Ethereum::PrivateKey.new(Arke::Ethereum::PrivateKey.new("\x01"*32).encode(:bin_compressed)).to_pubkey).to eq("\x03\x1b\x84\xc5V{\x12d@\x99]>\xd5\xaa\xba\x05e\xd7\x1e\x184`H\x19\xff\x9c\x17\xf5\xe9\xd5\xdd\x07\x8f")
    expect(Arke::Ethereum::PrivateKey.new(Arke::Ethereum::PrivateKey.new("\x01"*32).encode(:hex_compressed)).to_pubkey).to eq('031b84c5567b126440995d3ed5aaba0565d71e1834604819ff9c17f5e9d5dd078f')
  end

  it "test to_bitcoin_address" do
    expect(Arke::Ethereum::PrivateKey.new("\x01"*32).to_bitcoin_address).to eq('1BCwRkTsYzK5aNK4sdF7Bpti3PhrkPtLc4')
  end

  it "test to_address" do
    expect(Arke::Ethereum::PrivateKey.new("\x01"*32).to_address).to eq("\x1ad/\x0e<:\xf5E\xe7\xac\xbd8\xb0rQ\xb3\x99\t\x14\xf1")
  end

end
