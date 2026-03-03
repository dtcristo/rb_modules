# Rb::Package

This system brings strict, ES Module style encapsulation to Ruby using `Ruby::Box` (requires Ruby 4.0+). Every file is evaluated in a completely isolated namespace, preventing constant leaks and global namespace pollution.

## Exporting (`export`)

The `export` method exposes objects, methods, or values from the isolated box to the outside world. It has two modes: Single Export and Multiple Exports.

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

If a file acts as a collection of utilities, pass a Hash (via keyword arguments) to `export`.

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

There are two methods available globally to load these isolated files:

- `import(path)`: Resolves the path using Ruby's native `$LOAD_PATH` or gem lookup. Ideal for gems and libraries.
- `import_relative(path)`: Resolves the path relative to the directory of the file calling it (exactly like `require_relative`). Ideal for local project files.

How you receive the imported data depends on how you assign it.

### The Single Import

If the target file used a Single Export, `import` / `import_relative` returns that exact object.

```ruby
Customer = import_relative 'user'

alice = Customer.new("Alice")
```

### The Namespace Import

If the target file exported multiple items via a Hash, the import returns an anonymous Module containing those exports. You can assign it to a constant to act as a namespace.

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

Instead of assigning the entire namespace to a constant, you can use Ruby's rightward assignment (`=>`) pattern matching to pluck exactly what you need.

```ruby
import_relative('math') => { add:, version: }

puts add.(5, 5) # => 10
puts version    # => "1.0.0"
```

Rename an import with an alias:

```ruby
import_relative('math') => { add: sum }
puts sum.(10, 10) # => 20
```

### Importing Constants

Ruby's pattern matching enforces that local variable names must start with a lowercase letter. This creates a gotcha when trying to extract exported Constants using destructuring. Here are the recommended approaches:

**Option 1: Direct Namespace Access** (recommended for single constant)
```ruby
PI = import_relative('math')::PI

def calculate_area(r)
  PI * (r ** 2)
end
```

**Option 2: Use `fetch()` Method** (clean one-liner)
```ruby
PI = import_relative('math').fetch(:PI)

def calculate_area(r)
  PI * (r ** 2)
end
```

**Option 3: Use `fetch_values()` for Multiple Constants**
```ruby
PI, E = import_relative('math').fetch_values(:PI, :E)

def calculate_area(r)
  PI * (r ** 2)
end
```

**Option 4: Alias and Promote** (pattern matching approach)
```ruby
# 1. Destructure and alias to a lowercase local variable
import_relative('math') => { PI: pi }

# 2. Promote to a Constant in the current file
PI = pi 

def calculate_area(r)
  PI * (r ** 2)
end
```

### Importing from Bare Gems/Scripts

If a gem or script file doesn't export anything explicitly (no `export` call), `import` returns the isolated Box instance itself. This allows you to access any constants or methods defined within that gem/script directly through the Box namespace. See the "Importing Constants" section above for all available approaches.

```ruby
# Most direct approach
Faker = import('faker')::Faker

puts "Hello, #{Faker::Name.name}!"
```

Or with `fetch()`:

```ruby
Faker = import('faker').fetch(:Faker)

puts "Hello, #{Faker::Name.name}!"
```

## Examples

### Minimal

Four packages (`main`, `foo`, `bar`, `baz`) in a flat directory using `import_relative`. Demonstrates single/hash exports, cross-package dependencies, and destructuring.

```sh
RUBY_BOX=1 ruby examples/minimal/main.rb
```

### Complex

An adventure game with three packages in a `packages/` directory using zeitwerk-style naming. Demonstrates all features including `bundler/setup` for gem dependencies, cross-package imports, `fetch`/`fetch_values`, constants, and re-exports.

- **adventure**: Uses `faker` and `colorize` gems via its own `gems.rb` and `bundler/setup`
- **quest**: Hash exports with constants, version strings, and callable methods
- **loot**: Cross-package `import_relative` from quest, single export with hash

```sh
# Install adventure package gems (first time only)
cd examples/complex/packages/adventure && BUNDLE_GEMFILE=gems.rb bundle install && cd -

RUBY_BOX=1 ruby examples/complex/main.rb
```

## Running

```sh
# Run all tests
RUBY_BOX=1 rake test

# Run all examples
RUBY_BOX=1 rake examples

# Run a specific example
RUBY_BOX=1 rake example:minimal
RUBY_BOX=1 rake example:complex

# Run everything (default)
RUBY_BOX=1 rake
```
