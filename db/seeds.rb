# In the following block, I'm not using `create_or_update` method on purpose, to make the
# command output more clear
YAML::load_file(Rails.root.join('config', 'seeds.yml')).tap do |seeds|
  markets = seeds.fetch('markets')

  # Create or update exchanges
  seeds.fetch('exchanges').each do |exchange_params|
    exchange = Exchange.find_by(name: exchange_params['name'])

    if exchange.nil?
      puts "create exchange #{exchange_params['name']}: #{exchange_params}"
      exchange = Exchange.create!(exchange_params)
    else
      puts "update existing exchange #{exchange.name}: #{exchange_params}"
      exchange.update!(exchange_params)
    end

    if exchange.errors.any?
      puts "  #{exchange.name}: error: #{exchange.errors.messages}"
    end

    # for each exchange, create markets
    markets.each do |market_params|
      market = Market.find_by(name: market_params['name'], exchange_id: exchange.id)

      if market.nil?
        puts "  #{exchange.name}: create market #{market_params['name']}: #{market_params}"
        Market.create!(market_params.merge(exchange_id: exchange.id))
      else
        puts "  #{exchange.name}: update existing market #{market.name}: #{market_params}"
        market.update(market_params)
      end
    end
  end
  puts "End of seed"
end
