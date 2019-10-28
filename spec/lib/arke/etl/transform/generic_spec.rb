# frozen_string_literal: true

describe Arke::ETL::Transform::Generic do
  let(:config) do
    {
      "field" => "field",
      "apply" => "something",
    }
  end
  let(:transform) do
    Arke::ETL::Transform::Generic.new(config)
  end

  context "field is missing" do
    let(:config) { {"apply" => "something"} }

    it "raises" do
      expect { transform }.to raise_error(StandardError)
    end
  end

  context "apply is missing" do
    let(:config) { {"field" => "field"} }

    it "raises" do
      expect { transform }.to raise_error(StandardError)
    end
  end

  context "correct configuration" do
    it "applies the method on the field" do
      cb = double()
      object = double(field: double(something: nil))
      expect(cb).to receive(:call).with(object)
      expect(object).to receive(:field)
      expect(object.field).to receive(:something)
      transform.mount(&cb.method(:call))
      transform.call(object)
    end
  end
end
