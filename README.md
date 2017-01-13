# Triton::Http::Signing

Ruby gem that supports http-signing to auth against the Joyent Triton Cloudapi. As described in their API docs in [Appendix C](https://apidocs.joyent.com/cloudapi/#appendix-c-http-signature-authentication).

The gem uses ssh-agent to sign requests avoiding having to touch the private key.

This gem is a works in progress and currently only supports ssh-rsa keys. Adding support for other key types should not be too difficult.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'triton-http-signing'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install triton-http-signing

## Usage


```ruby
require "triton/http/signing"

signer = HttpSigner.new("account", "~/.ssh/id_rsa.pub")
signature_header = signer.signature("Sat, 10 Jan 2017 23:56:29 GMT")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Tests

```
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stevenwilliamson/triton-http-signing.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

