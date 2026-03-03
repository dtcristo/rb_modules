require_relative '../../lib/rb/package'

# Single import — Foo exports a module
Foo = import_relative 'foo'

# Namespace import — Bar exports a hash with methods and constants
Bar = import_relative 'bar'

puts '--- Foo ---'
puts Foo.hello

puts
puts '--- Bar (uses Baz internally) ---'
puts Bar.hello
puts "Bar::MAGIC = #{Bar::MAGIC}"
