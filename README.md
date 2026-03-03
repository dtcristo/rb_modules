# Rb::Package

This system brings strict, ES Module style encapsulation to Ruby using `Ruby::Box` (requires Ruby 4.0+). Every file is evaluated in a completely isolated namespace, preventing constant leaks and global namespace pollution.

## Exporting (`export`)

The export method exposes objects, methods, or values from the isolated box to the outside world. It has two modes: Single Export and Multiple Exports.

### Single Export

If a file represents exactly one concept (like a class or a single function), export that object directly.

```ruby
# user.rb
class User
  def initialize(name) = @name = name
end

export User
```

### Multiple Exports (Named Exports)

If a file acts as a collection of utilities, pass a Hash (via keyword arguments) to export.

```ruby
# math.rb
def add(a, b) = a + b

export(
  PI: 3.14159,
  version: "1.0.0",
  add: method(:add)
)
```

## Importing (`import`, `import_relative`)

There are two methods available globally to load these isolated files

- `import(path)`: Resolves the path using Ruby's native `$LOAD_PATH`. Ideal for standard library or gem-like
- `imports.import_relative(path)`: Resolves the path relative to the directory of the file calling it (exactly like `require_relative`). Ideal for local project files.

How you receive the imported data depends on how you assign it.

### The Single Import

If the target file used a Single Export, import returns that exact object.

```ruby
Customer = import 'user'

alice = Customer.new("Alice")
```

### The Namespace Import

If the target file exported multiple items via a Hash, import returns an anonymous Module containing those exports. You can assign this module to a constant to act as a namespace.

- Exported keys starting with a **Capital** letter become Constants on the module.
- Exported keys starting with a **lowercase** letter become singleton methods on the module.

```ruby
MathUtils = import_relative 'math'

# Accessing a constant
puts MathUtils::PI        # => 3.14159

# Accessing values and methods (both act as singleton methods)
puts MathUtils.version    # => "1.0.0"
puts MathUtils.add(5, 5)  # => 10
```

### The Destructuring Import (Pattern Matching)

Instead of assigning the entire namespace to a constant, you can use Ruby 3's rightward assignment (`=>`) pattern matching to pluck exactly what you need into your local scope.

```ruby
import_relative('math') => { add:, version: }

puts add.(5, 5) # => 10
puts version    # => "1.0.0"
```

### Aliased Destructuring & The "Constant" Gotcha

If you want to rename an import to avoid collisions, you map the exported key to a local variable name.

```ruby
import_relative('math') => { add: sum }
puts sum.(10, 10) # => 20
```

**⚠️ Important Gotcha for Constants:** Ruby's pattern matching enforces that local variable names must start with a lowercase letter. If you try to destructure a constant like `{ PI: }`, Ruby will throw a syntax error (`key must be valid as local variables`).

To extract an exported Constant, you must alias it to a lowercase local variable first. If you need it to be a Constant in your file, just promote it immediately:

```ruby
# 1. Destructure and alias to a lowercase local variable
import_relative('math') => { PI: pi }

# 2. Promote to a Constant in the current file
PI = pi 

def calculate_area(r)
  PI * (r ** 2)
end
```
 
 ## Example
 
 ```ruby
 cd example
 RUBY_BOX=1 ruby main.rb
 ```
