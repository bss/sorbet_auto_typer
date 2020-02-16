# typed: strict
require 'json'

module SorbetAutoTyper
  class Tracer
    extend T::Sig

    IOLike = T.type_alias do
      T.any(
        IO,
        StringIO
      )
    end

    sig { params(io_writer: IOLike, filter_path: String).void }
    def initialize(io_writer, filter_path='')
      @io_writer = io_writer
      @filter_path = filter_path
      @trace_point = T.let(TracePoint.new(:call, :return) do |trace|
        next if !trace.path.start_with?(filter_path)

        method = trace.self.method(trace.method_id)
        method_type = nil
        container = nil
        case method.receiver
        when Class
          method_type = 'class'
          container = method.receiver
        when Module
          method_type = 'module'
          container = method.receiver
        else
          method_type = 'instance'
          container = method.receiver.class
        end

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
            args: trace.parameters.map { |(type, name)| [type, name, type_from_value(trace.binding.eval(name.to_s))] },
          }
          @io_writer.puts(JSON.generate(data))
        elsif trace.event == :return
          data = {
            type: 'return',
            container: container,
            method_type: method_type,
            method_name: trace.method_id,
            return_class: type_from_value(trace.return_value),
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

    sig { params(value: Object).returns(T::Hash[Symbol, T.untyped]) }
    def type_from_value(value)
      case value
      when Hash
        {
          type: value.class.to_s,
          key_type: value.keys.first(100).map { |v| type_from_value(v) }.uniq,
          value_type: value.values.first(100).map { |v| type_from_value(v) }.uniq,
        }
      when Range, Array, Set
        { type: value.class.to_s, inner_type: T.must(value.first(100)).map { |v| type_from_value(v) }.uniq }
      else
        { type: value.class.to_s }
      end
    end

    sig { returns(TracePoint) }
    attr_reader :trace_point
  end
end