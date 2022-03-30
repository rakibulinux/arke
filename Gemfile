source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "fiddler-rb", "~>0.1.3", git: "https://github.com/genki/fiddler.git"

gemspec

gem "clamp", "~> 1.3.1"
gem "binance", "~> 1.2", git: "https://github.com/caherrerapa/binance.git"

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "pry", "~> 0.12"
  gem "faker", "~> 2.5"
  gem "webmock", "~> 3.5"
  gem "rexml"
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "bump", "~> 0.8"
  gem "shoulda-matchers", "~> 4.1.2"
  gem "rspec", "~> 3.9"
  gem "irb", "~> 1.0"
  gem "mime-types", "~> 3.3"
  gem "em-websocket"
end

gem "simplecov", require: false, group: :test
