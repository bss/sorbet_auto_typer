# typed: strong

class TypedHelperClass
  extend T::Sig

  sig { returns(Integer) }
  def method_with_signature
    42
  end
end