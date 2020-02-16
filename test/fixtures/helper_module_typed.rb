# typed: true

module HelperModule
  module Test
    extend T::Sig

    class << self
      extend T::Sig

      sig { returns(String) }
      def foo
        'test'
      end
    end

    sig { returns(Integer) }
    def self.bar
      0x9
    end
  end
end