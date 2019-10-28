# frozen_string_literal: true

describe Arke::ETL::Extract::Base do
  let(:extract) do
    Arke::ETL::Extract::Base.new({})
  end

  it "mounts callbacks" do
    cb1 = double(call: true).method(:call).to_proc
    cb2 = double(call: true).method(:call).to_proc
    extract.mount(&cb1)
    extract.mount(&cb2)
    expect(extract.instance_variable_get(:@callbacks)).to eq([cb1, cb2])
  end

  it "raises if start method is missing" do
    expect { extract.start }.to raise_error(StandardError)
  end
end
