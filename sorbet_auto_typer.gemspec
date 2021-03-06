lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sorbet_auto_typer/version"

Gem::Specification.new do |spec|
  spec.name          = "sorbet_auto_typer"
  spec.version       = SorbetAutoTyper::VERSION
  spec.authors       = ["Bo Stendal Sorensen"]
  spec.email         = ["bo@stendal-sorensen.net"]

  spec.summary       = "Automatically generate sorbet type signatures based on code-instrumentation"
  spec.description   = "This let's you automatically type up your codebase by instrumenting code, (e.g. using the test suite of the project)."
  spec.homepage      = "https://github.com/bss/sorbet_auto_typer"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bss/sorbet_auto_typer"
  spec.metadata["changelog_uri"] = "https://github.com/bss/sorbet_auto_typer/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'parser', '~> 2.7'
  spec.add_dependency "sorbet-runtime"
  spec.add_dependency "diff-lcs", "~> 1.3"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "sorbet"
end
