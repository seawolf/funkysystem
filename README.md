# FunkySystem

An enhanced version of system() that allows the capture of stdout,
stderr & also feeding data to stdin.

The main method is FunkySystem.run(cmd, stdin).

e.g.

result = FunkySystem.run(["bc"], "3+2\n4+23\nquit")
result.stdout # => "5\n27\n"

## Installation

Add this line to your application's Gemfile:

    gem 'funkysystem'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install funkysystem

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
