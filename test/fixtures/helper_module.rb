# typed: true

module HelperModule
  module Test
    class << self
      def foo
        'test'
      end
    end

    def self.bar
      0x9
    end
  end
end