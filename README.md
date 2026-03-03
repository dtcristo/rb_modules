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

There are two methods available globally to load these isolated files

- `import(path)`: Resolves the path using Ruby's native `$LOAD_PATH`. Ideal for standard library or gem-like
- `imports.import_relative(path)`: Resolves the path relative to the directory of the file calling it (exactly like `require_relative`). Ideal for local project files.

How you receive the imported data depends on how you assign it.

### The Single Import

If the target file used a Single Export, `import` returns that exact object.

```ruby
Customer = import 'user'

alice = Customer.new("Alice")
```

### The Namespace Import

If the target file exported multiple items via a Hash, `import` returns an anonymous Module containing those exports. You can assign it to a constant to act as a namespace.

- Exported keys starting with a **Capital** letter become Constants on the module.
- Exported keys starting with a **lowercase** letter become singleton methods on the module.

```ruby
MathUtils = import_relative 'math'

puts MathUtils::PI        # => 3.14159
puts MathUtils.version    # => "1.0.0"
puts MathUtils.add(5, 5)  # => 10
```

### The Destructuring Import (Pattern Matching)

Instead of assigning the entire namespace to a constant, you can use Ruby's rightward assignment (`=>`) pattern matching to pluck exactly what you need.

```ruby
import('math') => { add:, version: }

puts add.(5, 5) # => 10
puts version    # => "1.0.0"
```

Rename an import with an alias:

```ruby
import('math') => { add: sum }
puts sum.(10, 10) # => 20
```

### Symbol Promotion Targets

> **⚠️ Ruby Gotcha:** Pattern matching requires that the binding target in `{ KEY: target }` be a valid local variable name — it must start with a lowercase letter. Writing `{ PI: }` or `{ PI: MyConst }` is a `SyntaxError`.
>
> We would love to see Ruby updated to allow constant and variable binding targets directly in hash patterns, making this workaround unnecessary.

`Rb::Package` works around this limitation with **symbol promotion targets**. Instead of binding to a local variable, you supply a symbol that describes _where_ the value should land. The library promotes the value to that destination at the call site.

| Pattern                        | Effect                                          |
|--------------------------------|-------------------------------------------------|
| `{ KEY: :_ }`                  | Promotes value as constant `KEY`                |
| `{ KEY: :ConstName }`          | Promotes value as constant `ConstName`          |
| `{ KEY: :'Ns::Name' }`         | Promotes value as namespaced constant `Ns::Name`|
| `{ KEY: :'$global' }`          | Sets global variable `$global`                  |
| `{ KEY: :'@ivar' }`            | Sets instance variable `@ivar` at the call site |
| `{ KEY: :'@@cvar' }`           | Sets class variable `@@cvar` at the call site   |

Promotion happens transparently — the pattern match succeeds and no intermediate local variable is left behind.

#### Examples

```ruby
# Promote using the export key name as the constant
import('math') => { PI: :_ }
puts PI # => 3.14159

# Promote to a different constant name
import('math') => { PI: :CircleConstant }
puts CircleConstant # => 3.14159

# Promote to a namespaced constant
import('math') => { PI: :'Circle::Pi' }
puts Circle::Pi # => 3.14159

# Set a global variable
import('math') => { PI: :'$MATH_PI' }
puts $MATH_PI # => 3.14159

# Set an instance variable at the call site
import('math') => { PI: :'@pi' }
puts @pi # => 3.14159
```

### Legacy Gem Import

`import` also works with installed gems that were written before `Rb::Package` and therefore have no `EXPORTS` constant. In this case, `import` returns an anonymous proxy module. Any constant defined inside the gem can be accessed lazily, and pattern matching destructuring works via symbol promotion targets.

```ruby
import('faker') => { Faker: :_ }

puts Faker::Name.name # => "John Smith"
```

## Running the Examples

Simple example:
```sh
cd examples/simple
RUBY_BOX=1 ruby main.rb
```

Legacy gem example:
```sh
cd examples/legacy_gem
gem install faker
RUBY_BOX=1 ruby main.rb
```
