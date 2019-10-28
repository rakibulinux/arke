# -*- ruby -*-

SimpleCov.start do
  add_filter '/spec/'
end

# .simplecov
SimpleCov.start 'rails' do
  # any custom configs like groups and filters can be here at a central place
  add_group "ETL", "lib/arke/etl"
end
