# typed: strong
require 'sorbet-runtime'
require "sorbet_auto_typer/version"
require "sorbet_auto_typer/configuration"
require "sorbet_auto_typer/tracer"
require "sorbet_auto_typer/trace"
require "sorbet_auto_typer/source_rewriter"
require "sorbet_auto_typer/annotator"

module SorbetAutoTyper
  class Error < StandardError; end
  class MissingConfigurationError < Error; end
  class InvalidConfigurationError < Error; end
  class TracerAlreadyRunning < Error; end

  class << self
    extend T::Sig

    sig { void }
    def start!
      raise MissingConfigurationError.new if !@config
      raise InvalidConfigurationError.new unless @config.valid?
      raise TracerAlreadyRunning.new unless @current_tracer.nil?

      output_file = File.open(T.must(@config.output_file), 'w')

      @current_tracer = Tracer.new(output_file, T.must(@config.filter_path))
      @current_tracer.start!
    end

    sig { void }
    def stop!
      @current_tracer = T.let(@current_tracer, T.nilable(Tracer))
      unless @current_tracer.nil?
        @current_tracer.stop!
        @current_tracer = nil
      end
    end

    sig { params(blk: T.proc.params(arg0: Configuration).void).void }
    def configure(&blk)
      config = Configuration.new(output_file: nil)
      yield config
      @config = T.let(config, T.nilable(Configuration))
    end

    sig { void }
    def reset!
      stop!
      @config = nil
    end

    private
    sig { returns(T.nilable(Configuration)) }
    attr_reader :config
  end
end
