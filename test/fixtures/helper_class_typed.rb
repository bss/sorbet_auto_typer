# typed: true

class HelperClass
  extend T::Sig

  sig { params(return_a_num: T::Boolean).returns(T.any(Integer, String)) }
  def foo(return_a_num)
    if return_a_num
      1234
    else
      'a_string'
    end
  end

  sig { params(num: T.nilable(Integer)).returns(T.nilable(T.any(Float, String))) }
  def self.bar(num=nil)
    if num.nil?
      nil
    elsif num % 2 == 0
      'Even'
    else
      42.3
    end
  end

  class << self
    extend T::Sig

    sig { returns(HelperClass::AnotherClass) }
    def blarp
      AnotherClass.new
    end
  end

  class AnotherClass
  end
end
