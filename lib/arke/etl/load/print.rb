# frozen_string_literal: true

module Arke::ETL::Load
  class Print
    def initialize(_config); end

    def call(*args)
      puts "print: #{args}"
    end
  end
end
