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
          [arg_name.to_s, classes_to_rbi_sig(sigs.map(&:value_type).uniq)]
        end

        params_sig = nil
        if args_sigs.size > 0
          sig_str = args_sigs.map { |n,s| "#{n}: #{s}" }.join(', ')
          params_sig = "params(#{sig_str})"
        end

        return_klasses = traces.select(&:return?).map(&:return_class).uniq
        return_sig = classes_to_rbi_sig(return_klasses)
        if return_sig.nil? || return_sig == 'NilClass'
          return_sig = 'void'
        else
          return_sig = "returns(#{return_sig})"
        end

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
      types_to_look_for = in_sclass ? ['class', 'module'] : ['instance']
      @traces.select { |s| s.method_name == method_name.to_s && types_to_look_for.include?(s.method_type) }
    end

    def classes_to_rbi_sig(klasses)
      klasses = klasses.map do |kls|
        (kls == 'TrueClass' || kls == 'FalseClass') ? 'T::Boolean' : kls
      end.uniq
      if klasses.size == 0
        nil
      elsif klasses.size == 1
        klasses.first.to_s
      elsif klasses.include?('NilClass')
        inner_sig = classes_to_rbi_sig(klasses.reject { |k| k == 'NilClass'})
        "T.nilable(#{inner_sig})"
      else
        "T.any(#{klasses.map(&:to_s).join(', ')})"
      end
    end
  end
end