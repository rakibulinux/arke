# -*- encoding : ascii-8bit -*-

describe Arke::Ethereum do
  include Arke::Ethereum::Utils

  it "test keccak256" do
    expect(keccak256('')).to eq("\xc5\xd2F\x01\x86\xf7#<\x92~}\xb2\xdc\xc7\x03\xc0\xe5\x00\xb6S\xca\x82';{\xfa\xd8\x04]\x85\xa4p")
  end

  it "test keccak256_rlp" do
    expect(keccak256_rlp('')).to eq("V\xe8\x1f\x17\x1b\xccU\xa6\xff\x83E\xe6\x92\xc0\xf8n[H\xe0\x1b\x99l\xad\xc0\x01b/\xb5\xe3c\xb4!")
    expect(keccak256_rlp(1)).to eq("_\xe7\xf9w\xe7\x1d\xba.\xa1\xa6\x8e!\x05{\xee\xbb\x9b\xe2\xac0\xc6A\n\xa3\x8dO?\xbeA\xdc\xff\xd2")
    expect(keccak256_rlp([])).to eq("\x1d\xccM\xe8\xde\xc7]z\xab\x85\xb5g\xb6\xcc\xd4\x1a\xd3\x12E\x1b\x94\x8at\x13\xf0\xa1B\xfd@\xd4\x93G")
    expect(keccak256_rlp([1, [2,3], "4", ["5", [6]]])).to eq("YZ\xef\x85BA8\x89\x08?\x83\x13\x88\xcfv\x10\x0f\xd8a:\x97\xaf\xb8T\xdb#z#PF89")
  end

  it "test double_sha256" do
    expect(double_sha256('')).to eq("]\xf6\xe0\xe2v\x13Y\xd3\n\x82u\x05\x8e)\x9f\xcc\x03\x81SEE\xf5\\\xf4>A\x98?]L\x94V")
  end

  it "test ripemd160" do
    expect(ripemd160("\x00")).to eq("\xc8\x1b\x94\x934 \"\x1az\xc0\x04\xa9\x02B\xd8\xb1\xd3\xe5\x07\r")
  end

  it "test hash160" do
    expect(hash160("\x00")).to eq("\x9f\x7f\xd0\x96\xd3~\xd2\xc0\xe3\xf7\xf0\xcf\xc9$\xbe\xefO\xfc\xebh")
    expect(hash160_hex("\x00")).to eq("9f7fd096d37ed2c0e3f7f0cfc924beef4ffceb68")
  end

  it "test mod_exp" do
    expect(mod_exp(2, 10, 1023)).to eq(1)
  end

  it "test mod_mul" do
    expect(mod_mul(2, 4, 7)).to eq(1)
  end

  it "test base58_check_to_bytes" do
    expect(base58_check_to_bytes('12v3WKYzeJnRZWgfV3')).to eq('ethereum')
    expect(base58_check_to_bytes('x4BdNKWArBWmHMTgc')).to eq('ethereum')
  end

  it "test bytes_to_base58_check" do
    expect(bytes_to_base58_check("ethereum")).to eq('12v3WKYzeJnRZWgfV3')
    expect(bytes_to_base58_check("ethereum", 11)).to eq('x4BdNKWArBWmHMTgc')
  end

  it "test ceil32" do
    expect(ceil32(0)).to eq(0)
    expect(ceil32(1)).to eq(32)
    expect(ceil32(256)).to eq(256)
    expect(ceil32(250)).to eq(256)
  end

  it "test big_endian_to_int" do
    expect(big_endian_to_int("\xff")).to eq(255)
    expect(big_endian_to_int("\x00\x00\xff")).to eq(255)
  end

  it "test coerce_to_int" do
    expect(coerce_to_int("d\x13L\x8F\x0E\xD5*\x13\xBD\n\x00\xFF\x9F\xC6\xDBn\b2\xE3\x9E")).to eq(571329460454981322332848927582483177110542410654)
  end

  it "test normalize_address" do
    expect(normalize_address(Arke::Ethereum::Address::BLANK, allow_blank: true)).to eq(Arke::Ethereum::Address::BLANK)
    expect{ normalize_address(Arke::Ethereum::Address::BLANK) }.to raise_error(Arke::Ethereum::ValueError)
  end

  it "test mk_contract_address" do
    expect(mk_contract_address("\x00"*20, 0)).to eq("\xbdw\x04\x16\xa34_\x91\xe4\xb3Ev\xcb\x80JWo\xa4\x8e\xb1")
  end

  it "test decode_hex" do
    expect{ decode_hex('xxxx') }.to raise_error(TypeError)
    expect{ decode_hex("\x00\x00") }.to raise_error(TypeError)
  end

end
