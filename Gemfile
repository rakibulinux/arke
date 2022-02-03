source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.0'

gem 'clamp', '~> 1.3.1'
gem 'rbtree', '~> 0.4.2'
gem 'colorize', '~> 0.8.1'
gem 'faraday', '~> 1.4'
gem 'faye', '~> 1.2'
gem 'eventmachine', '~> 1.2'
gem 'em-synchrony', '~> 1.0'

# Ethereum
gem 'bitcoin-secp256k1', '~> 0.4'
gem 'digest-sha3-patched-ruby-3', '~> 1.1'
gem 'fiddler-rb', '~>0.1.3', git: "https://github.com/genki/fiddler.git"
gem 'eth', '~>0.4.17'
gem 'rlp'

## Exchanges
gem 'binance', '~> 1.2', git: "https://github.com/caherrerapa/binance.git"
gem 'bitx', '~> 0.2.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry', '~> 0.12'
  gem 'faker', '~> 2.5'
  gem 'webmock', '~> 3.5'
  gem 'rexml'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'bump', '~> 0.8'
  gem 'shoulda-matchers', '~> 4.1.2'
  gem "rspec", "~> 3.9"
  gem "irb", "~> 1.0"
  gem "mime-types", "~> 3.3"
  gem "em-websocket"
end

gem 'simplecov', require: false, group: :test

gem "rack", "~> 2.2"
