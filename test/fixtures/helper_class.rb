# typed: true

class HelperClass
  def foo(return_a_num)
    if return_a_num
      1234
    else
      'a_string'
    end
  end

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
    def blarp
      AnotherClass.new
    end
  end

  class AnotherClass
  end

  class ASelfClass < self
    def something
      ['A', 123]
    end
  end
end
