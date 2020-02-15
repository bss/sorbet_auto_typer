#typed: strict

module SorbetAutoTyper
  class Trace
    extend T::Sig

    sig { returns(String) }
    attr_accessor :method_name

    sig { returns(String) }
    attr_accessor :method_type

    sig { params(data: T::Hash[String, T.untyped]).returns(T.any(CallTrace, ReturnTrace)) }
    def self.from_json(data)
      type = data.delete('type')
      if type == 'call'
        CallTrace.new(data)
      elsif type == 'return'
        ReturnTrace.new(data)
      else
        raise ArgumentError, "Invalid type in data: '#{type}'"
      end
    end

    sig { params(options: T::Hash[String, T.untyped]).void }
    def initialize(options={})
      @container = T.let(options.fetch('container').constantize, T.any(Class, Module))
      @method_name = T.let(options.fetch('method_name'), String)
      @method_type = T.let(options.fetch('method_type'), String)
    end

    sig { returns(T.any(Class, Module)) }
    def owner
      if method.owner.singleton_class?
        T.cast(method, Method).receiver.ancestors.find { |a| !(a.singleton_method(@method_name.to_sym) rescue nil).nil? }
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
      if @method_type == 'instance'
        method = @container.instance_method(@method_name.to_sym)
      elsif @method_type == 'class' || @method_type == 'module'
        method = @container.method(@method_name.to_sym)
      else
        raise ArgumentError, "Invalid method_type '#{@method_type}'"
      end
      # if method.owner.singleton_class?
      #   real_owner = method.receiver.ancestors.find { |a| !(a.singleton_method(@method_name.to_sym) rescue nil).nil? }
      #   real_owner.singleton_method(@method_name.to_sym)
      # end
      method
    end

    sig { returns(T::Boolean) }
    def params?
      false
    end

    sig { returns(T::Boolean) }
    def return?
      false
    end
  end

  class Param < T::Struct
    const :type, String
    const :name, String
    const :value_type, String
  end

  class CallTrace < Trace
    sig { params(options: T::Hash[String, T.untyped]).void }
    def initialize(options={})
      super
      @args = T.let(options.fetch('args').map { |a| Param.new(type: a[0], name: a[1], value_type: a[2]) }, T::Array[Param])
    end

    sig { returns(T::Boolean) }
    def params?
      true
    end

    sig { returns(T::Array[Param]) }
    def args
      @args
    end
  end

  class ReturnTrace < Trace
    sig { returns(String) }
    attr_accessor :return_kls

    sig { params(options: T::Hash[String, T.untyped]).void }
    def initialize(options={})
      super
      @return_kls = T.let(options.fetch('return_class'), String)
    end

    sig { returns(T::Boolean) }
    def return?
      true
    end
  end
end