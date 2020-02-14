# typed: strict
require 'sorbet-runtime'
require "sorbet_auto_typer/version"
require "sorbet_auto_typer/configuration"

module SorbetAutoTyper
  class Error < StandardError; end
  class MissingConfigurationError < Error; end

  class << self
    extend T::Sig

    sig { void }
    def start!
      raise MissingConfigurationError.new unless config
    end

    sig { void }
    def stop!
    end

    sig { params(blk: T.untyped).void }
    def configure(&blk)
      config = Configuration.new(output_file: nil)
      yield config
      @config = T.let(config, T.nilable(Configuration))
    end

    private
    sig { returns(T.nilable(Configuration)) }
    attr_reader :config
  end
end
