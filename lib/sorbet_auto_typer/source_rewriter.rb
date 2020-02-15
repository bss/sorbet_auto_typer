# typed: ignore
require 'parser'
require 'parser/current'

module SorbetAutoTyper
  class SourceRewriter < Parser::TreeRewriter
    def initialize(signatures)
      super()
      @signatures = signatures
      @in_sclass = false
    end

    def on_module(node)
      indent = ' ' * (node.loc.column+2)
      insert_after(node.loc.name, "\n#{indent}extends T::Sig\n")
      super
    end

    def on_class(node)
      if @signatures.map(&:owner).uniq.any? { |kls| node.children[0] == Parser::CurrentRuby.parse(kls.to_s) }
        indent = ' ' * (node.loc.column+2)
        insert_after((node.children[1] || node.children[0]).loc.name, "\n#{indent}extends T::Sig\n")
      end
      super
    end

    def on_sclass(node)
      @in_sclass = true
      out = super
      @in_sclass = false
      out
    end

    def on_def(node)
      method_name = node.children[0]
      signatures = signatures_for(method_name, @in_sclass)
      if signatures.size > 0
        args = signatures.select(&:params?).flat_map(&:args)
        args_sigs = args.group_by(&:name).map do |arg_name, sigs|
          [arg_name.to_s, classes_to_rbi_sig(sigs.map(&:value_type).uniq)]
        end

        params_sig = nil
        if args_sigs.size > 0
          sig_str = args_sigs.map { |n,s| "#{n}: #{s}" }.join(', ')
          params_sig = "params(#{sig_str})"
        end

        return_klasses = signatures.select(&:return?).map(&:return_kls).uniq
        return_sig = classes_to_returns_rbi(return_klasses)
        return_sig = return_sig != 'void' ? "returns(#{return_sig})" : return_sig

        rbi_sig = [params_sig, return_sig].compact.join('.')

        sig_indent = ' ' * (node.loc.column/2)
        indent = ' ' * node.loc.column
        insert_before(node.loc.expression, "sig { #{rbi_sig} }\n#{indent}")
      end
      super
    end

    # def on_defs(node)
    #   binding.pry
    #   node
    # end

    private
    def signatures_for(method_name, in_sclass)
      type_to_look_for = in_sclass ? 'class' : 'instance'
      @signatures.select { |s| s.method_name == method_name.to_s && s.method_type == type_to_look_for }
    end

    def classes_to_returns_rbi(klasses)
      if klasses.size == 0 || (klasses.size == 1 && klasses.first == NilClass)
        'void'
      else
        classes_to_rbi_sig(klasses)
      end
    end
  
    def classes_to_rbi_sig(klasses)
      klasses = klasses.map do |kls|
        (kls == TrueClass || kls == FalseClass) ? T::Boolean : kls
      end.uniq
      if klasses.size == 0
        nil
      elsif klasses.size == 1
        klasses.first.to_s
      elsif klasses.size == 2 && klasses.include?(TrueClass) && klasses.include?(FalseClass)
        'T::Boolean'
      elsif klasses.include?(NilClass)
        inner_sig = classes_to_rbi_sig(klasses.reject { |k| k == NilClass})
        "T.nilable(#{inner_sig})"
      else
        "T.any(#{klasses.map(&:to_s)}.join(', ')})"
      end
    end
  end
end