#typed: strict
module SorbetAutoTyper
  class Annotator
    extend T::Sig

    sig { params(traces: T::Array[Trace]).void }
    def initialize(traces)
      @traces = T.let(traces.group_by(&:method_file), T::Hash[String, T::Array[Trace]])
    end

    sig { params(source_file: String).returns(String) }
    def annotate_file(source_file)
      code = File.read(source_file)
      traces_for_file = traces.fetch(source_file)
      buffer = Parser::Source::Buffer.new('(example)')
      buffer.source = code
      temp = Parser::CurrentRuby.parse(code)
      rewriter = SorbetAutoTyper::SourceRewriter.new(traces_for_file)

      # Rewrite the AST, returns a String with the new form.
      rewriter.rewrite(buffer, temp)
    end

    private
    sig { returns(T::Hash[String, T::Array[Trace]]) }
    attr_reader :traces
  end
end