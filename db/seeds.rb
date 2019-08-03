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

    puts
  end
end

# FIXME: make seed file for development
## if Rails.env.development?
##   User.create!(email: 'admin@barong.io', level: 3, uid: 'ID123456789') unless User.find_by(uid: 'ID123456789')
## 
##   source = Account.create!(user: User.first, exchange: Exchange.find_by(name: :bitfaker))
##   target = Account.create!(user: User.first, exchange: Exchange.find_by(name: :rubykube))
## 
##   Strategy.create!(user: User.first, source: source, target: target, source_market: Market.first, target_market: Market.last, driver: :copy)
## end
