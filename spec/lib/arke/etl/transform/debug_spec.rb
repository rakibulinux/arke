# frozen_string_literal: true

describe Arke::ETL::Transform::Debug do
  let(:config) do
    {
      "id" => "42",
    }
  end
  let(:transform) do
    Arke::ETL::Transform::Debug.new(config)
  end

  context "id is missing" do
    let(:config) { {} }

    it "defaults to class name" do
      expect(transform.id).to eq("debug")
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
      transform.call("a", "b", "c")
    end
  end
end
