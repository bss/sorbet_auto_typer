# typed: true
require 'date'

module HelperModule
  module Test
    class << self
      def foo
        'test'
      end
    end

    def self.bar
      nil
    end
  end

  def self.hash_tester(arr, reverse=false)
    if reverse
      arr.zip(arr.reverse).to_h
    else
      arr.zip(arr.map(&:ord)).to_h
    end
  end

  def self.range_tester(range)
    if range.cover?(5)
      Date.new(2020, 1, 1)..Date.new(2020, 12, 31)
    else
      Set.new([4,'5',6,6])
    end
  end
end