# typed: ignore
require "test_helper"

class AnnotatorTest < Minitest::Test
  extend T::Sig

  sig { void }
  def test_annotator
    trace_data = StringIO.new
    tracer = SorbetAutoTyper::Tracer.new(trace_data, filter_path=Dir.pwd)
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
    HelperModule.hash_tester(['lol', 'foo', 45, 'bar', 24], true)
    HelperModule.range_tester(1..4)
    HelperModule.range_tester(4..10)
    HelperModule::Test.bar
    HelperModule::Test.const_in_singleton_class
    HelperModule.empty_array
    HelperClass::ASelfClass.new.something
    tracer.stop!
    
    traces = trace_data.string.split("\n").map do |l|
      SorbetAutoTyper::MethodTrace.from_trace_line(l)
    end
    
    annotator = SorbetAutoTyper::Annotator.new(traces)
    
    all_files = traces.map(&:method_file).uniq
    all_files.map do |source_file_path|
      typed_file_path = File.join(Dir.pwd, 'test', 'fixtures', File.basename(source_file_path).sub('.rb', '_typed.rb'))
      expected_output = File.read(typed_file_path)
      actual_output = annotator.annotate_file(source_file_path)

      assert_equal expected_output, actual_output
    end
  end
end