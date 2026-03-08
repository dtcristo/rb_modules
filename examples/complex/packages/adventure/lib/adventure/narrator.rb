# frozen_string_literal: true

module Adventure
  class Narrator
    def initialize(prefix: 'Narrator')
      @prefix = prefix
    end

    def announce(message)
      puts "[#{@prefix}] #{message}".colorize(:green)
    end

    def describe(message)
      puts "  [#{@prefix}] #{message}".colorize(:yellow)
    end

    def victory(message)
      puts "[#{@prefix}] #{message}".colorize(:magenta)
    end
  end
end
