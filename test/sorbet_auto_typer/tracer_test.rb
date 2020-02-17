# typed: ignore
require "test_helper"

class TracerTest < Minitest::Test
  extend T::Sig

  sig { void }
  def test_tracer_traces_method_calls
    temp_file = Tempfile.new
    tracer = SorbetAutoTyper::Tracer.new(temp_file.path, filter_path=Dir.pwd)
    tracer.start!
    HelperClass.bar(27)
    HelperClass.bar
    HelperClass.new.foo(false)
    HelperClass.bar(28)
    HelperClass.new.foo(true)
    TypedHelperClass.new.method_with_signature # Should not show up below since it's typed
    HelperModule::Test.foo
    HelperClass.blarp
    HelperModule.hash_tester(['a', 'b', 'c', 'd', 'e'])
    HelperModule.hash_tester(['lol', 'foo', 45, 'bar', 24], { a: [1, 'ff', { ['a', 3] => 4}] })
    HelperModule.range_tester(1..4)
    HelperModule.range_tester(4..10)
    HelperModule::Test.bar
    HelperModule::Test.const_in_singleton_class
    HelperModule.empty_array
    HelperClass::ASelfClass.new.something
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
      "C|HelperClass|class|blarp",
      "R|HelperClass|class|blarp|D;HelperClass::AnotherClass",
      "C|HelperModule|class|hash_tester|arr|A;(D;String)|reverse|D;FalseClass",
      "R|HelperModule|class|hash_tester|H;(D;String);(D;Integer)",
      "C|HelperModule|class|hash_tester|arr|A;(D;String;D;Integer)|reverse|H;(D;Symbol);(A;(D;Integer;D;String;H;(A;(D;String;D;Integer));(D;Integer)))",
      "R|HelperModule|class|hash_tester|H;(D;String;D;Integer);(D;Integer;D;String)",
      "C|HelperModule|class|range_tester|range|R;(D;Integer)",
      "R|HelperModule|class|range_tester|S;(D;Integer;D;String)",
      "C|HelperModule|class|range_tester|range|R;(D;Integer)",
      "R|HelperModule|class|range_tester|R;(D;Date)",
      "C|HelperModule::Test|class|bar",
      "R|HelperModule::Test|class|bar|D;NilClass",
      "C|HelperModule::Test|class|const_in_singleton_class",
      /R|HelperModule::Test|class|const_in_singleton_class|D;.*::PrivateClass/,
      "C|HelperModule|class|empty_array",
      "R|HelperModule|class|empty_array|A;()",
      "C|HelperClass::ASelfClass|instance|something",
      "R|HelperClass::ASelfClass|instance|something|A;(D;String;D;Integer)",
    ]
    actual_output = File.read(temp_file.path).split("\n")
    assert_equal(expected_output.size, actual_output.size)
    expected_output.each_with_index do |expected, idx|
      assert_match expected, actual_output[idx]
    end
  end
end