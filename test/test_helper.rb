$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))

require 'minitest/autorun'
require 'rb/package'

module TestHelpers
  # Returns a mock exportable module backed by a simple keyword hash.
  #
  # IMPORTANT: This helper MUST remain in a separate file (test_helper.rb)
  # from the test assertions.  The `define_singleton_method` block below
  # creates the `deconstruct_keys` closure; its source location is recorded
  # as *this* file.  The TracePoint armed by ivar/cvar promotions is filtered
  # to fire only in the *caller's* file (the test file), not here, so that
  # `self` in the TracePoint callback belongs to the test object rather than
  # to the anonymous Module.
  def make_exports(**hash)
    exports = hash
    mod = Module.new
    mod.define_singleton_method(:deconstruct_keys) do |keys|
      result = keys ? exports.slice(*keys) : exports.dup
      Rb::Package.auto_promote(result, caller_locations(1, 10))
      result
    end
    mod
  end
end
