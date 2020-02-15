# typed: ignore
require "test_helper"

class TracerTest < Minitest::Test
  extend T::Sig

  def parse_tracer_output(output)
    output.split("\n").map { |o| JSON.parse(o) }
  end

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
      {
        'type' => 'call',
        'container' => 'HelperClass',
        'method_type' => 'class',
        'method_name' => 'bar',
        'args' => [['opt', 'num', 'Integer']],
      },
      {
        'type' => 'return',
        'container' => 'HelperClass',
        'method_type' => 'class',
        'method_name' => 'bar',
        'return_class' => 'Float',
      },

      {
        'type' => 'call',
        'container' => 'HelperClass',
        'method_type' => 'class',
        'method_name' => 'bar',
        'args' => [['opt', 'num', 'NilClass']],
      },
      {
        'type' => 'return',
        'container' => 'HelperClass',
        'method_type' => 'class',
        'method_name' => 'bar',
        'return_class' => 'NilClass',
      },

      {
        'type' => 'call',
        'container' => 'HelperClass',
        'method_type' => 'instance',
        'method_name' => 'foo',
        'args' => [['req', 'return_a_num', 'FalseClass']],
      },
      {
        'type' => 'return',
        'container' => 'HelperClass',
        'method_type' => 'instance',
        'method_name' => 'foo',
        'return_class' => 'String',
      },

      {
        'type' => 'call',
        'container' => 'HelperClass',
        'method_type' => 'class',
        'method_name' => 'bar',
        'args' => [['opt', 'num', 'Integer']],
      },
      {
        'type' => 'return',
        'container' => 'HelperClass',
        'method_type' => 'class',
        'method_name' => 'bar',
        'return_class' => 'String',
      },

      {
        'type' => 'call',
        'container' => 'HelperClass',
        'method_type' => 'instance',
        'method_name' => 'foo',
        'args' => [['req', 'return_a_num', 'TrueClass']],
      },
      {
        'type' => 'return',
        'container' => 'HelperClass',
        'method_type' => 'instance',
        'method_name' => 'foo',
        'return_class' => 'Integer',
      },

      {
        'type' => 'call',
        'container' => 'HelperModule::Test',
        'method_type' => 'module',
        'method_name' => 'foo',
        'args' => [],
      },
      {
        'type' => 'return',
        'container' => 'HelperModule::Test',
        'method_type' => 'module',
        'method_name' => 'foo',
        'return_class' => 'String',
      },
    ]
    actual_output = parse_tracer_output(output.string)
    assert_equal expected_output, actual_output
  end
end