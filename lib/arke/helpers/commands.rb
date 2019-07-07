module Arke::Helpers
  module Commands

    def conf
      @conf ||= YAML.load_file(config)
    end

    def load_configuration
      strategy_file = File.join(::Rails.root, "config/strategies.yml")
      raise "File #{strategy_file} not found" unless File.exists?(strategy_file)
      config = YAML.load_file(strategy_file)

      Arke::Configuration.define { |c| c.strategy = config['strategy'] }
    end

    def strategies_configs
      if conf["strategies"] && conf["strategies"].is_a?(Array)
        strategies = conf["strategies"]
      else
        strategies = []
      end

      if conf["strategy"] && conf["strategy"].is_a?(Hash)
        strategies << conf["strategy"]
      end

      if dry?
        strategies.map! do |s|
          s["dry"] = dry?
          s["target"]["driver"] = "bitfaker"
          s
        end
      end
      strategies.filter! do |s|
        if s["enabled"] == false
          Arke::Log.warn "Strategy ID:#{s["id"]} disabled"
          false
        else
          true
        end
      end
      strategies
    end

    def safe_yield(blk, *args)
      begin
        blk.call(*args)
      rescue StandardError => e
        Arke::Log.error "#{e}: #{e.backtrace.join("\n")}"
      end
    end

    def each_platform(&blk)
      strategies_configs.each do |c|
        puts "Strategy ID #{c["id"]}"
        Array(c["sources"]).each do |ex|
          safe_yield(blk, ex)
        end
        if c["target"]
          safe_yield(blk, c["target"])
        end
      end
    end
  end
end
