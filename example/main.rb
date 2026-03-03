$LOAD_PATH.unshift('../lib')
$LOAD_PATH.unshift('.')
require 'rb/package'

puts '--- 1. Single Import ---'
Customer = import 'user'
alice = Customer.new('Alice')
puts alice.greet
puts

puts '--- 2. Nested Imports ---'
AdvancedMath = import 'math_tools/advanced'

puts "Area of a circle (r=10): #{AdvancedMath.circle_area(10)}"
puts "Re-exported Add: #{AdvancedMath.add(15, 5)}"
puts "Module Version: #{AdvancedMath.version}"
puts

puts '--- 3. Destructuring ---'
import('math_tools/basic') => { subtract: }
puts "10 - 4 = #{subtract.(10, 4)}"
