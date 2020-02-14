#typed: strict
module SorbetAutoTyper
  class Configuration < T::Struct
    extend T::Sig

    prop :output_file, T.nilable(String)
    prop :filter_path, T.nilable(String)

    sig { returns(T::Boolean) }
    def valid?
      return false if output_file.nil?
      return false if filter_path.nil?

      true
    end
  end
end