# Bar depends on Baz via import_relative
Baz = import_relative 'baz'

def hello
  "Hello from Bar! (#{Baz.hello})"
end

export(hello: method(:hello), MAGIC: 42)
