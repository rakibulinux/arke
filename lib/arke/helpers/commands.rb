module Arke::Helpers
  module Commands

    def conf
      @conf ||= YAML.load_file(config)
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

    def accounts_configs
      if conf["accounts"] && conf["accounts"].is_a?(Array)
        accounts = conf["accounts"]
      else
        accounts = []
      end
      accounts
    end

    def safe_yield(blk, *args)
      begin
        account = accounts_configs.select { |a| a["id"] == args.first["account_id"] }.first
        blk.call(*args, account)
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
