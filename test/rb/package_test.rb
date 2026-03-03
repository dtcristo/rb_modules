require_relative '../test_helper'

# Tests for Rb::Package's symbol-based auto-promotion system.
#
# Each test uses `make_exports` (defined in test_helper.rb, NOT this file) to
# build a mock exportable module, then exercises a pattern match that triggers
# `deconstruct_keys` -> `auto_promote` -> Prism AST walk.
class PackagePromotionTest < Minitest::Test
  include TestHelpers

  # ---------------------------------------------------------------------------
  # Constant promotion
  # ---------------------------------------------------------------------------

  def test_underscore_promotes_as_export_key
    m = make_exports(MyConst: 42)
    m => { MyConst: :_ }
    assert_equal 42, Object.const_get(:MyConst)
  ensure
    Object.send(:remove_const, :MyConst) rescue nil
  end

  def test_named_constant_promotion
    m = make_exports(source: 99)
    m => { source: :NamedValue }
    assert_equal 99, Object.const_get(:NamedValue)
  ensure
    Object.send(:remove_const, :NamedValue) rescue nil
  end

  def test_namespaced_constant_promotion
    m = make_exports(pi: Math::PI)
    m => { pi: :'RbPkgTest::Pi' }
    assert_in_delta Math::PI, RbPkgTest::Pi
  ensure
    Object.send(:remove_const, :RbPkgTest) rescue nil
  end

  def test_multiple_constant_promotions
    m = make_exports(Alpha: 1, Beta: 2)
    m => { Alpha: :_, Beta: :_ }
    assert_equal 1, Object.const_get(:Alpha)
    assert_equal 2, Object.const_get(:Beta)
  ensure
    Object.send(:remove_const, :Alpha) rescue nil
    Object.send(:remove_const, :Beta) rescue nil
  end

  def test_constant_and_local_in_same_pattern
    m = make_exports(Gamma: 10, delta: 20)
    m => { Gamma: :_, delta: }
    assert_equal 10, Object.const_get(:Gamma)
    assert_equal 20, delta
  ensure
    Object.send(:remove_const, :Gamma) rescue nil
  end

  # ---------------------------------------------------------------------------
  # Global variable promotion
  # ---------------------------------------------------------------------------

  def test_global_variable_promotion
    m = make_exports(answer: 42)
    m => { answer: :'$__rb_pkg_test_global' }
    assert_equal 42, $__rb_pkg_test_global
  ensure
    eval('$__rb_pkg_test_global = nil', TOPLEVEL_BINDING)
  end

  # ---------------------------------------------------------------------------
  # Instance variable promotion (TracePoint-based)
  # ---------------------------------------------------------------------------

  def test_ivar_promotion
    m = make_exports(score: 77)
    m => { score: :'@rb_pkg_test_ivar' }
    assert_equal 77, @rb_pkg_test_ivar
  end

  # ---------------------------------------------------------------------------
  # Class variable promotion (TracePoint-based)
  # ---------------------------------------------------------------------------

  def test_cvar_promotion
    m = make_exports(count: 5)
    m => { count: :'@@rb_pkg_test_cvar' }
    assert_equal 5, @@rb_pkg_test_cvar
  end

  # ---------------------------------------------------------------------------
  # Literal symbol matching must NOT be broken
  # ---------------------------------------------------------------------------

  def test_lowercase_symbol_is_not_a_promotion_target
    # :active is a literal value -- no promotion should occur, match must work
    m = make_exports(status: :active)
    matched = false
    m => { status: :active }
    matched = true
    assert matched
  end

  def test_literal_symbol_mismatch_raises
    m = make_exports(status: :active)
    assert_raises(NoMatchingPatternError) { m => { status: :inactive } }
  end

  def test_non_matching_symbols_leave_result_untouched
    # Value is :active; pattern asks for :active.  auto_promote must not
    # replace it with a promotion target and must leave the match working.
    m = make_exports(kind: :pending)
    result = m.deconstruct_keys([:kind])
    assert_equal :pending, result[:kind]
  end

  # ---------------------------------------------------------------------------
  # Multiline hash pattern
  # ---------------------------------------------------------------------------

  def test_multiline_hash_pattern
    m = make_exports(One: 1, Two: 2)
    m => {
      One: :_,
      Two: :_
    }
    assert_equal 1, Object.const_get(:One)
    assert_equal 2, Object.const_get(:Two)
  ensure
    Object.send(:remove_const, :One) rescue nil
    Object.send(:remove_const, :Two) rescue nil
  end

  # ---------------------------------------------------------------------------
  # Mixed pattern: promotion targets alongside shorthand locals
  # ---------------------------------------------------------------------------

  def test_shorthand_local_alongside_promotion
    m = make_exports(Pi: Math::PI, radius: 5)
    m => { Pi: :_, radius: }
    assert_in_delta Math::PI, Object.const_get(:Pi)
    assert_equal 5, radius
  ensure
    Object.send(:remove_const, :Pi) rescue nil
  end

  # ---------------------------------------------------------------------------
  # Edge case: already-defined constant is not overwritten
  # ---------------------------------------------------------------------------

  def test_existing_constant_not_overwritten
    Object.const_set(:Frozen, :original)
    m = make_exports(Frozen: :new_value)
    m => { Frozen: :_ }
    # promote_const skips if already defined
    assert_equal :original, Frozen
  ensure
    Object.send(:remove_const, :Frozen) rescue nil
  end
end
