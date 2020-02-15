# typed: strict
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "sorbet_auto_typer"

require "minitest/autorun"

require 'fixtures/helper_class'
require 'fixtures/typed_helper_class'
require 'fixtures/helper_module'
