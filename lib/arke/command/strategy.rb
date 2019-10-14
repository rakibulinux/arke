module Arke
  module Command
    class Strategy < ::Clamp::Command
      class Debug < ::Clamp::Command
        option "--orderbook", "FILE_PATH", "input file of BitFaker source", default: "spec/support/fixtures/bitfinex.yaml"

        parameter "STRATEGY_NAME", "Class name of the strategy to run", attribute_name: :strategy_name

        def build_config(strategy_name, orderbook)
          {
            "type" => strategy_name,
            "debug" => true,
            "params" => {
              "spread_bids" => 0.02,
              "spread_asks" => 0.01,
              "limit_bids" => 1.5,
              "limit_asks" => 1.0,
              "levels_algo" => "constant",
              "levels_size" => 0.01,
              "levels_count" => 5,
              "side" => "both",
            },
            "sources" => [
              "driver" => "bitfaker",
              "market" => "abcxyz",
              "orderbook" => orderbook,
            ],
          }
        end

        def build_dax(config)
          dax = {}
          config["sources"].each { |ex_config|
            ex = Arke::Exchange.create(ex_config)
            dax[ex_config["driver"].to_sym] = ex
            ex.start
          }
          dax
        end

        def execute
          config = build_config(strategy_name, orderbook)
          dax = build_dax(config)
          s = Arke::Strategy.create(config)
          s.call(dax)
          s.debug_infos.each do |name, data|
            puts name
            if data.is_a?(Arke::Orderbook::Orderbook)
              puts data.to_s(2)
            else
              pp data
            end
          end
        end
      end

      subcommand "debug", "Debug a strategy", Debug
    end
  end
end
