# frozen_string_literal: true

module Arke::ETL::Transform
  class Debug < Base
    def call(*args)
      puts "#{id}: #{args}"
      emit(*args)
    end
  end
end
