require 'colorize'

module Adventure
  class Narrator
    def announce(message)
      puts message.colorize(:green)
    end

    def describe(message)
      puts "  #{message}".colorize(:yellow)
    end

    def victory(message)
      puts message.colorize(:magenta)
    end
  end
end
