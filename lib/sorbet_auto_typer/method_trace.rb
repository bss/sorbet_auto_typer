#typed: strict

module SorbetAutoTyper
  class MethodTrace < T::Struct
    class Param
      extend T::Sig

      sig { params(args: String).returns(T::Array[Param]) }
      def self.param_list_from_args_string(args)
        args.split(Tracer::OUTPUT_DELIMITER).each_slice(2).map do |(name, type_str)|
          Param.new(name: T.must(name), type: MethodTrace.sorbet_type_from_string_encoding(T.must(type_str)))
        end
      end

      sig { params(name: String, type: T::Types::Base).void }
      def initialize(name:, type:)
        @name = name
        @type = type
      end

      sig { returns(String) }
      attr_reader :name

      sig { returns(T::Types::Base) }
      attr_reader :type
    end

    extend T::Sig

    const :container, T.any(Class, Module)
    const :method_type, String
    const :method_name, String
    const :args, T.nilable(T::Array[Param])
    const :return_class, T.nilable(T::Types::Base)

    sig { params(line: String).returns(MethodTrace) }
    def self.from_trace_line(line)
      type, container, method_type, method_name, args_or_return = line.split(Tracer::OUTPUT_DELIMITER, 5)
      case type
      when Tracer::OUTPUT_TYPE_CALL
        SorbetAutoTyper::MethodTrace.new(
          container: Object.const_get(T.must(container)),
          method_type: T.must(method_type),
          method_name: T.must(method_name),
          args: args_or_return.nil? ? [] : Param.param_list_from_args_string(args_or_return),
          return_class: nil,
        )
      when Tracer::OUTPUT_TYPE_RETURN
        SorbetAutoTyper::MethodTrace.new(
          container: Object.const_get(T.must(container)),
          method_type: T.must(method_type),
          method_name: T.must(method_name),
          args: nil,
          return_class: sorbet_type_from_string_encoding(T.must(args_or_return)),
        )
      else
        raise ArgumentError, "Invalid type in data: '#{type}'"
      end
    end

    sig { params(type_str: String).returns(T::Types::Base) }
    def self.sorbet_type_from_string_encoding(type_str)
      return T.untyped if type_str == ''

      subtypes_def = unpack_subtypes_one_level(type_str)
      subtypes = []
      while subtypes_def.size > 0
        output_type = subtypes_def.shift
        case output_type
        when Tracer::OUTPUT_TYPE_HASH
          key_type = sorbet_type_from_string_encoding(T.must(subtypes_def.shift))
          value_type = sorbet_type_from_string_encoding(T.must(subtypes_def.shift))
          subtypes << T::Types::TypedHash.new(keys: key_type, values: value_type)
        when Tracer::OUTPUT_TYPE_RANGE
          inner_type = sorbet_type_from_string_encoding(T.must(subtypes_def.shift))
          subtypes << T::Types::TypedRange.new(inner_type)
        when Tracer::OUTPUT_TYPE_ARRAY
          inner_type = sorbet_type_from_string_encoding(T.must(subtypes_def.shift))
          subtypes << T::Types::TypedArray.new(inner_type)
        when Tracer::OUTPUT_TYPE_SET
          inner_type = sorbet_type_from_string_encoding(T.must(subtypes_def.shift))
          subtypes << T::Types::TypedSet.new(inner_type)
        when Tracer::OUTPUT_TYPE_DEFAULT
          begin
            subtypes << T::Types::Simple.new(Object.const_get(T.must(subtypes_def.shift)))
          rescue NameError
            subtypes << T.untyped
          end
        else
          raise ArgumentError, "Invalid type string: '#{type_str}'"
        end
      end
      T::Types::Union.new(subtypes)
    end

    sig { params(str: String).returns(T::Array[String]) }
    def self.unpack_subtypes_one_level(str)
      level = 0
      str.split('').reduce(['']) do |memo, char|
        if char == Tracer::OUTPUT_TYPE_INNER_LEFT
          memo.last << char if level > 0
          level += 1
        elsif char == Tracer::OUTPUT_TYPE_INNER_RIGHT
          level -= 1
          memo.last << char if level > 0
        elsif char == Tracer::OUTPUT_TYPE_DELIMITER && level == 0
          memo << ''
        else
          memo.last << char
        end
        memo
      end
    end

    # sig { params(str: String).return() }
    # def self.decode_subtype(str)
    # end

    sig { returns(T.any(Class, Module)) }
    def owner
      if method.owner.singleton_class?
        T.cast(method, Method).receiver.ancestors.find { |a| !(a.singleton_method(method_name.to_sym) rescue nil).nil? }
      else
        method.owner
      end
    end

    sig { returns(String) }
    def method_file
      method.source_location.first
    end

    sig { returns(T.any(Method, UnboundMethod)) }
    def method
      if method_type == 'instance'
        method = container.instance_method(method_name.to_sym)
      elsif method_type == 'class'
        method = container.method(method_name.to_sym)
      else
        raise ArgumentError, "Invalid method_type '#{method_type}'"
      end
      # if method.owner.singleton_class?
      #   real_owner = method.receiver.ancestors.find { |a| !(a.singleton_method(@method_name.to_sym) rescue nil).nil? }
      #   real_owner.singleton_method(@method_name.to_sym)
      # end
      method
    end

    sig { returns(T::Boolean) }
    def params?
      !args.nil?
    end

    sig { returns(T::Boolean) }
    def return?
      !return_class.nil?
    end
  end
end