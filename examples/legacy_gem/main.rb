$LOAD_PATH.unshift('../../lib')
require 'rb/package'

import('faker') => { Faker: :_ }

puts "Hello, #{Faker::Name.name}!"
