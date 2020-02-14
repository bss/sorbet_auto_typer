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
    end

    SorbetAutoTyper.start!
  ensure
    SorbetAutoTyper.stop!
  end

  sig { void }
  def test_invalid_configuration_raises_error
    SorbetAutoTyper.configure do |c|
      c.output_file = nil
    end

    assert_raises SorbetAutoTyper::InvalidConfigurationError do
      SorbetAutoTyper.start!
    end
  end
end
