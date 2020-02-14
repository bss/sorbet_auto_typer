# typed: strict
require 'sorbet-runtime'
require "sorbet_auto_typer/version"
require "sorbet_auto_typer/configuration"
require "sorbet_auto_typer/tracer"

module SorbetAutoTyper
  class Error < StandardError; end
  class MissingConfigurationError < Error; end
  class InvalidConfigurationError < Error; end

  class << self
    extend T::Sig

    sig { void }
    def start!
      raise MissingConfigurationError.new if config.nil?
      raise InvalidConfigurationError.new unless T.must(config).valid?
    end

    sig { void }
    def stop!
    end

    sig { params(blk: T.proc.params(arg0: Configuration).void).void }
    def configure(&blk)
      config = Configuration.new(output_file: nil)
      yield config
      @config = T.let(config, T.nilable(Configuration))
    end

    sig { void }
    def reset!
      @config = nil
    end

    private
    sig { returns(T.nilable(Configuration)) }
    attr_reader :config
  end
end
