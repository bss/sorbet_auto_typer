# frozen_string_literal: true
# typed: false
require 'json'

module SorbetAutoTyper
  class Tracer
    METHOD_TYPE_INSTANCE = 'instance'
    METHOD_TYPE_CLASS = 'class'
    METHOD_TYPE_MODULE = 'module'
    OUTPUT_TYPE_CALL = 'C'
    OUTPUT_TYPE_RETURN = 'R'
    OUTPUT_DELIMITER = '|'
    OUTPUT_TYPE_INNER_LEFT = '('
    OUTPUT_TYPE_INNER_RIGHT = ')'
    OUTPUT_TYPE_DELIMITER = ';'
    OUTPUT_TYPE_DEFAULT = 'D'
    OUTPUT_TYPE_ARRAY = 'A'
    OUTPUT_TYPE_RANGE = 'R'
    OUTPUT_TYPE_SET = 'S'
    OUTPUT_TYPE_HASH = 'H'

    def initialize(io_writer, filter_path='')
      @io_writer = io_writer
      @io_writer.sync = false
      @filter_path = filter_path
      @trace_point = TracePoint.new(:call, :return) do |trace|
        handle_trace(trace)
      end
    end

    def start!
      trace_point.enable
    end

    def stop!
      trace_point.disable
      @io_writer.close
    end

    private

    def handle_trace(trace)
      return if !trace.path.start_with?(@filter_path)

      method = trace.self.method(trace.method_id)

      # Skip if we already got a signature
      return unless method.source_location.first.start_with?(@filter_path)

      method_type = nil
      container = nil
      case method.receiver
      when Class, Module
        method_type = METHOD_TYPE_CLASS
        container = method.receiver
      else
        method_type = METHOD_TYPE_INSTANCE
        container = method.receiver.class
      end

      # Skip traces of internal methods
      return if container == self.class

      if trace.event == :call
        @io_writer.write(OUTPUT_TYPE_CALL)
        @io_writer.write(OUTPUT_DELIMITER)
        @io_writer.write(container.to_s)
        @io_writer.write(OUTPUT_DELIMITER)
        @io_writer.write(method_type.to_s)
        @io_writer.write(OUTPUT_DELIMITER)
        @io_writer.write(trace.method_id.to_s)
        trace.parameters.each do |(_type, name)|
          @io_writer.write(OUTPUT_DELIMITER)
          @io_writer.write(name)
          @io_writer.write(OUTPUT_DELIMITER)
          @io_writer.write(type_from_value(trace.binding.eval(name.to_s)))
        end
        @io_writer.write("\n")
      elsif trace.event == :return
        @io_writer.write(OUTPUT_TYPE_RETURN)
        @io_writer.write(OUTPUT_DELIMITER)
        @io_writer.write(container.to_s)
        @io_writer.write(OUTPUT_DELIMITER)
        @io_writer.write(method_type.to_s)
        @io_writer.write(OUTPUT_DELIMITER)
        @io_writer.write(trace.method_id.to_s)
        @io_writer.write(OUTPUT_DELIMITER)
        @io_writer.write(type_from_value(trace.return_value))
        @io_writer.write("\n")
      end
    end

    def type_from_value(value)
      case value
      when Hash
        "".dup.concat(
          OUTPUT_TYPE_HASH,
          OUTPUT_TYPE_DELIMITER,
          OUTPUT_TYPE_INNER_LEFT,
          value.keys.first(10).map { |v| type_from_value(v) }.uniq.join(OUTPUT_TYPE_DELIMITER),
          OUTPUT_TYPE_INNER_RIGHT,
          OUTPUT_TYPE_DELIMITER,
          OUTPUT_TYPE_INNER_LEFT,
          value.values.first(10).map { |v| type_from_value(v) }.uniq.join(OUTPUT_TYPE_DELIMITER),
          OUTPUT_TYPE_INNER_RIGHT,
        )
      when Range
        "".dup.concat(
          OUTPUT_TYPE_RANGE,
          OUTPUT_TYPE_DELIMITER,
          OUTPUT_TYPE_INNER_LEFT,
          value.first(10).map { |v| type_from_value(v) }.uniq.join(OUTPUT_TYPE_DELIMITER),
          OUTPUT_TYPE_INNER_RIGHT,
        )
      when Array
        "".dup.concat(
          OUTPUT_TYPE_ARRAY,
          OUTPUT_TYPE_DELIMITER,
          OUTPUT_TYPE_INNER_LEFT,
          value.first(10).map { |v| type_from_value(v) }.uniq.join(OUTPUT_TYPE_DELIMITER),
          OUTPUT_TYPE_INNER_RIGHT,
        )
      when Set
        "".dup.concat(
          OUTPUT_TYPE_SET,
          OUTPUT_TYPE_DELIMITER,
          OUTPUT_TYPE_INNER_LEFT,
          value.first(10).map { |v| type_from_value(v) }.uniq.join(OUTPUT_TYPE_DELIMITER),
          OUTPUT_TYPE_INNER_RIGHT,
        )
      else
        "".dup.concat(
          OUTPUT_TYPE_DEFAULT,
          OUTPUT_TYPE_DELIMITER,
          value.class.to_s,
        )
      end
    end

    attr_reader :trace_point
  end
end