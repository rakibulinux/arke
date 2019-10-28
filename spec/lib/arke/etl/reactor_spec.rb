# frozen_string_literal: true

describe Arke::ETL::Transform::Debug do
  let(:dry_run) { false }
  let(:config) do
    {
      "log_level" => "DEBUG",
      "jobs"      => jobs
    }
  end
  let(:jobs) do
    [
      {
        "extract"   => extract,
        "transform" => pre_process_transform,
        "process"   => process,
      }
    ]
  end
  let(:extract) { "Base" }
  let(:pre_process_transform) do
    [
      "Debug" => {
        "id" => "pre-debug"
      }
    ]
  end
  let(:process_transform) { ["Base"] }
  let(:load_config) { "Print" }
  let(:process) do
    [
      "transform" => process_transform,
      "load"      => load_config
    ]
  end

  let(:reactor) do
    Arke::ETL::Reactor.new(config, dry_run)
  end

  context "valid configuration is provided" do
    it "instantiates the ETL tree" do
      reactor
    end
  end

  context "hash classes" do
    let(:extract) { "Base" }
    let(:process_transform) do
      [
        "Debug" => {
          "id" => "post-debug"
        }
      ]
    end
    let(:load_config) do
      {
        "Print" => {}
      }
    end
    it "instantiates the ETL tree" do
      reactor
    end
  end

  context "flat config instead of array" do
    context "string transform" do
      let(:process_transform) { "Base" }
      it "instantiates the ETL tree" do
        reactor
      end
    end

    context "hash transform" do
      let(:process_transform) { {"Base" => {"id" => "56"}} }
      it "instantiates the ETL tree" do
        reactor
      end
    end
  end

  context "bad config" do
    context "extract Array" do
      let(:extract) { ["Base"] }
      it "raises an error" do
        expect { reactor }.to raise_error(StandardError)
      end
    end
    context "wrong jobs" do
      let(:jobs) { "Base" }
      it "raises an error" do
        expect { reactor }.to raise_error(StandardError)
      end
    end

    context "wrong klass format" do
      let(:pre_process_transform) do
        [
          [
            "Debug"
          ]
        ]
      end
      it "raises an error" do
        expect { reactor }.to raise_error(StandardError)
      end
    end

    context "string process" do
      let(:process) { "Base" }
      it "raises an error" do
        expect { reactor }.to raise_error(StandardError)
      end
    end
  end
end
