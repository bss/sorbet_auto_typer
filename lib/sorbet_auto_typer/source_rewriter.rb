# typed: true
require 'parser'
require 'parser/current'

module SorbetAutoTyper
  class SourceRewriter < Parser::TreeRewriter
    extend T::Sig

    sig { params(traces: T::Array[MethodTrace]).void }
    def initialize(traces)
      @traces = traces
      @in_sclass = T.let(false, T::Boolean)
      @signature_counter = 0
    end

    sig { params(node: Parser::AST::Node).returns(Parser::AST::Node) }
    def on_module(node)
      maybe_extend_t_sig(node, node.children[0].loc.name) do
        super
      end
    end

    sig { params(node: Parser::AST::Node).returns(Parser::AST::Node) }
    def on_class(node)
      maybe_extend_t_sig(node, (node.children[1] || node.children[0]).loc.name) do
        super
      end
    end

    sig { params(node: Parser::AST::Node).returns(Parser::AST::Node) }
    def on_sclass(node)
      maybe_extend_t_sig(node, node.children[0].loc.expression) do
        in_sclass do
          super
        end
      end
    end

    sig { params(node: Parser::AST::Node).returns(Parser::AST::Node) }
    def on_def(node)
      insert_signature_for_method(node.children[0], node)
      super
    end

    def on_defs(node)
      in_sclass do
        insert_signature_for_method(node.children[1], node)
        super
      end
    end

    private

    def insert_signature_for_method(method_name, node)
      traces = traces_for(method_name, @in_sclass)
      if traces.size > 0
        args = traces.select(&:params?).flat_map(&:args)
        args_sigs = args.group_by(&:name).map do |arg_name, sigs|
          [arg_name.to_s, T::Types::Union.new(sigs.map(&:type)).name]
        end

        params_sig = nil
        if args_sigs.size > 0
          sig_str = args_sigs.map { |n,s| "#{n}: #{s}" }.join(', ')
          params_sig = "params(#{sig_str})"
        end

        return_type = T::Types::Union.new(traces.select(&:return?).map(&:return_class))
        return_sig = "returns(#{return_type.name})"

        rbi_sig = [params_sig, return_sig].compact.join('.')

        sig_indent = ' ' * (node.loc.column/2)
        indent = ' ' * node.loc.column
        insert_before(node.loc.expression, "sig { #{rbi_sig} }\n#{indent}")

        @signature_counter += 1
      end
    end

    def in_sclass
      @in_sclass = true
      out = yield
      @in_sclass = false
      out
    end

    def maybe_extend_t_sig(node, location)
      sig_counter_before = @signature_counter
      out = yield
      if @signature_counter > sig_counter_before
        indent = ' ' * (node.loc.column+2)
        insert_after(location, "\n#{indent}extend T::Sig\n")
        @signature_counter = sig_counter_before
      end
      out
    end

    def traces_for(method_name, in_sclass)
      type_to_look_for = in_sclass ? 'class' : 'instance'
      @traces.select { |s| s.method_name == method_name.to_s && s.method_type == type_to_look_for }
    end
  end
end