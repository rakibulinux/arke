# frozen_string_literal: true

describe Arke::Helpers::Flags do
  include Arke::Helpers::Flags

  it "adds and removes binary flags to the object" do
    expect(flag?(0x1)).to eq(false)
    expect(flag?(0x2)).to eq(false)

    apply_flags(0x1)
    expect(flag?(0x1)).to eq(true)
    expect(flag?(0x2)).to eq(false)

    apply_flags(0x2)
    expect(flag?(0x1)).to eq(true)
    expect(flag?(0x2)).to eq(true)

    remove_flags(0x2)
    expect(flag?(0x1)).to eq(true)
    expect(flag?(0x2)).to eq(false)

    remove_flags(0x1)
    expect(flag?(0x1)).to eq(false)
    expect(flag?(0x2)).to eq(false)

    apply_flags(0x1 | 0x2)
    expect(flag?(0x1)).to eq(true)
    expect(flag?(0x2)).to eq(true)

    remove_flags(0x1 | 0x2)
    expect(flag?(0x1)).to eq(false)
    expect(flag?(0x2)).to eq(false)
  end
end
