# frozen_string_literal: true

describe Arke::ETL::Transform::Sample do
  let(:config) { {} }
  let(:transform) do
    Arke::ETL::Transform::Sample.new(config)
  end

  context "ratio is a string" do
    let(:config) { {"ratio" => "1"} }

    it "raises" do
      expect { transform }.to raise_error(StandardError)
    end
  end

  context "ratio is an object" do
    let(:config) { {"ratio" => double()} }

    it "raises" do
      expect { transform }.to raise_error(StandardError)
    end
  end

  context "ratio is unset" do
    let(:config) { {"ratio" => nil} }

    it "defaults to 1" do
      expect(transform.ratio).to eq(1)
    end
  end

  context "ratio is unset" do
    it "defaults to 1" do
      expect(transform.ratio).to eq(1)
    end
  end

  context "ratio is set" do
    let(:config) { {"ratio" => 0.2} }

    it "defaults to 1" do
      expect(transform.ratio).to eq(0.2)
    end
  end

  context "ratio is 100%" do
    let(:config) { {"ratio" => 1.0} }

    it "takes all" do
      expect(transform.ratio).to eq(1)
      cb = double(call: true).method(:call).to_proc
      transform.mount(&cb)
      expect(cb).to receive(:call).with(:object)
      transform.call(:object)
    end
  end

  context "ratio is 0%" do
    let(:config) { {"ratio" => 0.0} }

    it "drops all" do
      expect(transform.ratio).to eq(0)
      cb = double(call: true).method(:call).to_proc
      transform.mount(&cb)
      expect(cb).not_to receive(:call)
      transform.call(:object)
    end
  end
end
