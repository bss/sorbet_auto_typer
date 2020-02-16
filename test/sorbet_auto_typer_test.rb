# typed: strict
require "test_helper"
require 'securerandom'

class SorbetAutoTyperTest < Minitest::Test
  extend T::Sig

  sig { void }
  def setup
    SorbetAutoTyper.reset!
  end

  sig { void }
  def test_configuration_must_be_setup_before_starting
    assert_raises SorbetAutoTyper::MissingConfigurationError do
      SorbetAutoTyper.start!
    end

    SorbetAutoTyper.configure do |c|
      c.output_file = File.join(Dir.pwd, 'tmp', "#{SecureRandom.uuid}.sigs")
      c.filter_path = Dir.pwd
    end

    SorbetAutoTyper.start!
  ensure
    SorbetAutoTyper.stop!
  end

  sig { void }
  def test_invalid_configuration_raises_error
    SorbetAutoTyper.configure do |c|
      c.output_file = nil
      c.filter_path = nil
    end

    assert_raises SorbetAutoTyper::InvalidConfigurationError do
      SorbetAutoTyper.start!
    end
  end

  sig { void }
  def test_starting_tracer_twice_raises_error
    SorbetAutoTyper.configure do |c|
      c.output_file = File.join(Dir.pwd, 'tmp', "#{SecureRandom.uuid}.sigs")
      c.filter_path = Dir.pwd
    end

    SorbetAutoTyper.start!

    assert_raises SorbetAutoTyper::TracerAlreadyRunning do
      SorbetAutoTyper.start!
    end
  end

  sig { void }
  def test_end_to_end
    output_file = File.join(Dir.pwd, 'tmp', "#{SecureRandom.uuid}.sigs")
    SorbetAutoTyper.configure do |c|
      c.output_file = output_file
      c.filter_path = Dir.pwd
    end

    SorbetAutoTyper.start!
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
    SorbetAutoTyper.stop!

    assert_equal File.read(output_file), File.read(File.join(Dir.pwd, 'test', 'fixtures', 'expected_output.sigs'))
  end
end
