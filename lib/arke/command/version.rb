# frozen_string_literal: true

module Arke::Command
  class Version < Clamp::Command
    def execute
      puts "Arke version #{read_version}"
    end

    def read_version
      dir = __dir__
      loop do
        return File.read(File.join(dir, 'VERSION')).strip if File.exist?(File.join(dir, 'VERSION'))
        dir = File.expand_path("..", dir)
        raise "VERSION file not found" if dir == '/'
      end
    end
  end
end
