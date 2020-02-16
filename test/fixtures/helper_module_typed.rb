# typed: true
require 'date'

module HelperModule
  extend T::Sig

  module Test
    extend T::Sig

    class << self
      extend T::Sig

      sig { returns(String) }
      def foo
        'test'
      end

      sig { returns(T.untyped) }
      def const_in_singleton_class
        PrivateClass.new
      end

      class PrivateClass; end
    end

    sig { returns(NilClass) }
    def self.bar
      nil
    end
  end

  sig { params(arr: T.any(T::Array[String], T::Array[T.any(Integer, String)]), reverse: T::Boolean).returns(T.any(T::Hash[String, Integer], T::Hash[T.any(Integer, String), T.any(Integer, String)])) }
  def self.hash_tester(arr, reverse=false)
    if reverse
      arr.zip(arr.reverse).to_h
    else
      arr.zip(arr.map(&:ord)).to_h
    end
  end

  sig { params(range: T::Range[Integer]).returns(T.any(T::Range[Date], T::Set[T.any(Integer, String)])) }
  def self.range_tester(range)
    if range.cover?(5)
      Date.new(2020, 1, 1)..Date.new(2020, 12, 31)
    else
      Set.new([4,'5',6,6])
    end
  end

  sig { returns(T::Array[T.untyped]) }
  def self.empty_array
    []
  end
end