# SorbetAutoTyper

SorbetAutoTyper is a tool that is able to add sorbet signatures to files by instrumenting code, for example by running the test suite of a project.

## Installation

Add this line to your application's Gemfile (you probably want to add it in the development/test section):

```ruby
gem 'sorbet_auto_typer'
```

And then execute:

    $ bundle

## Usage

SorbetAutoTyper works in two steps:

1. Instrumentation
2. Analysis

### Instrumentation

The first step is to instrument the code. To be able to instrument even a large codebase, SorbetAutoTyper will stop instrumenting a method after a specific amount of calls. Underneath the hood the ruby `TracePoint` API is used to ensure maximum speed.

To instrument a codeblock, first configure the gem:

```ruby
SorbetAutoTyper.configure do |c|
  c.output_file = File.join(Dir.pwd, 'tmp', "#{SecureRandom.uuid}.sig")
  c.filter_path = File.join(Dir.pwd, 'lib')
end
```

This will set up the gem to output a signature file with a random name to the `tmp` directory and only inspect files in the `lib` directory.
This configuration only needs to be done once pr. process.

Next we can start and stop SorbetAutoTyper using `SorbetAutoTyper.start!` and `SorbetAutoTyper.stop!`.

Instrumenting a simple file could look like this:

```ruby
SorbetAutoTyper.start!
a = MyModule::MyClass.new
a.hello
SorbetAutoTyper.stop!
```

In the context of a test runner like RSpec, the following could be added to the spec helper of the project:

```ruby
SorbetAutoTyper.configure do |c|
  c.output_file = File.join(Dir.pwd, 'tmp', "#{SecureRandom.uuid}.sig")
  c.filter_path = File.join(Dir.pwd, 'lib')
end

RSpec.configure do |config|
  config.before(:suite) do
    SorbetAutoTyper.start!
  end

  config.after(:suite) do
    SorbetAutoTyper.stop!
  end
end
```

### Analysis

Running the analysis is as simple as running the `sorbet-auto-typer` tool within your project. If you run it without any arguments, it will print a bit of help:

```bash
$ bundle exec sorbet-auto-typer
Error: Please provide a SIGNATURE_FILE.

sorbet-auto-typer [OPTIONS] ... SIGNATURE_FILE

-h, --help:
   show help

--dry, -d:
   do not overwrite files, only display desired changes

--verbose, -v:
   more verbose output

SIGNATURE_FILE: Signature file to use for auto-generated types
```

The `--dry` and `--verbose` flags will make sure none of the source files are overwritten and provide a diff of the files. Those are recommended options on the first run.

When you are ready to run `SorbetAutoTyper` on your project, simply run it without any options and it will add method signatures to the source files in the project.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bss/sorbet_auto_typer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SorbetAutoTyper project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bss/sorbet_auto_typer/blob/master/CODE_OF_CONDUCT.md).
