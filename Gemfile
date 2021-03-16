source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 2.6'

gem 'clamp', '~> 1.3.1'
gem 'rbtree', '~> 0.4.2'
gem 'colorize', '~> 0.8.1'
gem 'faraday', '~> 0.15.4'
gem 'faraday_middleware', '~> 0.13.1'
gem 'faye', '~> 1.2'
gem 'eventmachine', '~> 1.2'
gem 'em-synchrony', '~> 1.0'

## Exchanges
gem 'binance', '~> 1.2'
gem 'bitx', '~> 0.2.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry', '~> 0.12'
  gem 'faker', '~> 2.5'
  gem 'webmock', '~> 3.5'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'bump', '~> 0.8'
  gem 'shoulda-matchers', '~> 4.1.2'
  gem "rspec", "~> 3.9"
  gem "irb", "~> 1.0"
  gem "mime-types", "~> 3.3"
end

gem 'simplecov', require: false, group: :test

gem "rack", "~> 2.2"
