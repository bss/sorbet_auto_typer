#typed: strict

module SorbetAutoTyper
  class MethodTrace < T::Struct
    class Param < T::Struct
      const :type, String
      const :name, String
      const :value_type, String
    end

    extend T::Sig

    const :container, T.any(Class, Module)
    const :method_type, String
    const :method_name, String
    const :args, T.nilable(T::Array[Param])
    const :return_class, T.nilable(String)

    sig { params(data: T::Hash[String, T.untyped]).returns(MethodTrace) }
    def self.from_json(data)
      case data.fetch('type')
      when 'call'
        SorbetAutoTyper::MethodTrace.new(
          container: Object.const_get(data.fetch('container')),
          method_type: data.fetch('method_type'),
          method_name: data.fetch('method_name'),
          args: data.fetch('args').map { |a| Param.new(type: a[0], name: a[1], value_type: a[2]) },
          return_class: nil,
        )
      when 'return'
        SorbetAutoTyper::MethodTrace.new(
          container: Object.const_get(data.fetch('container')),
          method_type: data.fetch('method_type'),
          method_name: data.fetch('method_name'),
          args: nil,
          return_class: data.fetch('return_class'),
        )
      else
        raise ArgumentError, "Invalid type in data: '#{data.fetch('type')}'"
      end
    end

    sig { returns(T.any(Class, Module)) }
    def owner
      if method.owner.singleton_class?
        T.cast(method, Method).receiver.ancestors.find { |a| !(a.singleton_method(method_name.to_sym) rescue nil).nil? }
      else
        method.owner
      end
    end

    # sig { returns(String) }
    def method_file
      method.source_location.first
    end

    sig { returns(T.any(Method, UnboundMethod)) }
    def method
      if method_type == 'instance'
        method = container.instance_method(method_name.to_sym)
      elsif method_type == 'class' || method_type == 'module'
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