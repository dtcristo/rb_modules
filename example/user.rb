class User
  def initialize(name) = @name = name
  def greet = "Hello, #{@name}!"
end

# Exporting the class directly
export User
