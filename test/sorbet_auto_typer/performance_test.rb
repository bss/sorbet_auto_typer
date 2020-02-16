# typed: ignore
require "test_helper"
require 'securerandom'
require 'benchmark'
require 'ruby-prof'

class SorbetAutoTyperTest < Minitest::Test
  extend T::Sig

  TOTAL_TRACE_COUNT = 100_000

  sig { void }
  def setup
    SorbetAutoTyper.reset!
  end

  sig { void }
  def test_performance
    output_file = File.join(Dir.pwd, 'tmp', "#{SecureRandom.uuid}.sigs")
    SorbetAutoTyper.configure do |c|
      c.output_file = output_file
      c.filter_path = File.join(Dir.pwd, 'test')
    end

    SorbetAutoTyper.start!

    t = Benchmark.measure {
      (TOTAL_TRACE_COUNT/20).times do
        # The following block will result in 20 traces
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
      end
    }

    SorbetAutoTyper.stop!

    line_count = `wc -l #{output_file}`.strip.split(" ").first.to_i
    assert_equal(TOTAL_TRACE_COUNT, line_count)
    assert_in_delta(1.0, t.total, 0.5)
  end
end
