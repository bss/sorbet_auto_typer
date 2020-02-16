# typed: ignore
require "test_helper"

class TracerTest < Minitest::Test
  extend T::Sig

  sig { void }
  def test_tracer_traces_method_calls
    output = StringIO.new
    tracer = SorbetAutoTyper::Tracer.new(output, filter_path=Dir.pwd)
    tracer.start!
    HelperClass.bar(27)
    HelperClass.bar
    HelperClass.new.foo(false)
    HelperClass.bar(28)
    HelperClass.new.foo(true)
    TypedHelperClass.new.method_with_signature # Should not show up below since it's typed
    HelperModule::Test.foo
    tracer.stop!

    expected_output = [
      "C|HelperClass|class|bar|num|D;Integer",
      "R|HelperClass|class|bar|D;Float",
      "C|HelperClass|class|bar|num|D;NilClass",
      "R|HelperClass|class|bar|D;NilClass",
      "C|HelperClass|instance|foo|return_a_num|D;FalseClass",
      "R|HelperClass|instance|foo|D;String",
      "C|HelperClass|class|bar|num|D;Integer",
      "R|HelperClass|class|bar|D;String",
      "C|HelperClass|instance|foo|return_a_num|D;TrueClass",
      "R|HelperClass|instance|foo|D;Integer",
      "C|HelperModule::Test|class|foo",
      "R|HelperModule::Test|class|foo|D;String",
    ]
    actual_output = output.string.split("\n")
    assert_equal expected_output, actual_output
  end
end