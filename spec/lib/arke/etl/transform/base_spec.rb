# frozen_string_literal: true

describe Arke::ETL::Transform::Base do
  let(:config) do
    {
      "id"        => "42",
      "somewhere" => "something",
    }
  end
  let(:transform) do
    Arke::ETL::Transform::Base.new(config)
  end

  context "id is missing" do
    let(:config) { {} }

    it "defaults to class name" do
      expect(transform.id).to eq("base")
    end
  end

  context "config provided" do
    it "stores the config" do
      expect(transform.instance_variable_get(:@config)).to eq(config)
    end
  end

  context "one callback is provided" do
    it "calls the callback when emit is called" do
      cb = double()
      expect(cb).to receive(:call).with("a", "b", "c")
      transform.mount(&cb.method(:call))
      transform.emit("a", "b", "c")
    end
  end
end
