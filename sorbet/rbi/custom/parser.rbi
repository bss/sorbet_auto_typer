# typed: strong

class Parser::Ruby26
  extend T::Sig

  sig { params(source: String).returns(Parser::AST::Node) }
  def self.parse(source); end
end

class Parser::TreeRewriter
  extend T::Sig

  sig { params(buffer: Parser::Source::Buffer, temp: Parser::AST::Node).returns(Parser::AST::Node) }
  def self.rewrite(buffer, temp); end
end

class Parser::AST::Node
  extend T::Sig

  def children
  end
end
