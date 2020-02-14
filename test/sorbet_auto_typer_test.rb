# typed: strict
require "test_helper"

class SorbetAutoTyperTest < Minitest::Test
  extend T::Sig

  sig { void }
  def test_that_it_has_a_version_number
    refute_nil ::SorbetAutoTyper::VERSION
  end

  sig { void }
  def test_it_does_something_useful
    assert false
  end
end
