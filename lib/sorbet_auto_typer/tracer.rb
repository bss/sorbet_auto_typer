# typed: strict
require 'json'

IOLike = T.type_alias do
  T.any(
    IO,
    StringIO
  )
end

module SorbetAutoTyper
  class Tracer
    extend T::Sig

    sig { params(io_writer: IOLike, filter_path: String).void }
    def initialize(io_writer, filter_path='')
      @io_writer = io_writer
      @filter_path = filter_path
      @trace_point = T.let(TracePoint.new(:call, :return) do |trace|
        next if !trace.path.start_with?(filter_path)

        method = trace.self.method(trace.method_id)
        method_type = method.receiver.is_a?(Class) ? 'class' : 'instance'
        container = method.receiver.is_a?(Class) ? method.receiver : method.receiver.class

        # Skip traces of internal methods
        next if container == self.class

        # Skip if we already got a signature
        next if T::Utils.signature_for_instance_method(method.owner, trace.method_id)

        if trace.event == :call
          data = {
            type: 'call',
            container: container,
            method_type: method_type,
            method_name: trace.method_id,
            args: trace.parameters.map { |(type, name)| [type, name, trace.binding.eval(name.to_s).class.to_s] },
          }
          @io_writer.puts(JSON.generate(data))
        elsif trace.event == :return
          data = {
            type: 'return',
            container: container,
            method_type: method_type,
            method_name: trace.method_id,
            return_class: trace.return_value.class,
          }
          @io_writer.puts(JSON.generate(data))
        end
      end, TracePoint)
    end

    sig { void }
    def start!
      trace_point.enable
    end

    sig { void }
    def stop!
      trace_point.disable
      @io_writer.close
    end

    private

    sig { returns(TracePoint) }
    attr_reader :trace_point
  end
end