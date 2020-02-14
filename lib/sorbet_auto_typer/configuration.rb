#typed: strict
module SorbetAutoTyper
  class Configuration < T::Struct
    extend T::Sig

    prop :output_file, T.nilable(String)

    sig { returns(T::Boolean) }
    def valid?
      return false if output_file.nil?

      true
    end
  end
end