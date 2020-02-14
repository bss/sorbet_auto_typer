#typed: strict
module SorbetAutoTyper
  class Configuration < T::Struct
    prop :output_file, T.nilable(String)
  end
end