source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 2.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.0'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.4.4', '< 0.6.0'
# Use Puma as the app server
gem 'puma', '~> 3.11'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production

gem 'redis', '~> 4.0'

gem 'clamp', '~> 1.3.1'
gem 'vault-rails', '~> 0.5.0', git: 'http://github.com/rubykube/vault-rails'
gem 'rbtree', '~> 0.4.2'
gem 'colorize', '~> 0.8.1'
gem 'faraday', '~> 0.15.4'
gem 'faraday_middleware', '~> 0.13.1'
gem 'faye', '~> 1.2'
gem 'peatio', '~> 0.6.2'
gem 'influxdb', '~> 0.7.0'

gem 'eventmachine', '~> 1.2'
gem 'em-synchrony', '~> 1.0'

## Exchanges
gem 'binance', '~> 1.2'
gem 'bitx', '~> 0.2.2'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry', '~> 0.12'
  gem 'faker', '~> 2.5'
  gem 'factory_bot_rails', '~> 5.0'
  gem 'rspec-rails', '~> 3.8'
  gem 'webmock', '~> 3.5'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'bump', '~> 0.8'
  gem 'shoulda-matchers', '~> 4.1.2'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'simplecov', require: false, group: :test

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "irb", "~> 1.0", :groups => [:development, :test]
