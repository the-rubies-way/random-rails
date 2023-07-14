# ActiveRecord::Random

The most perfomant way to get random records from ActiveRecord. In fact, it's the only way to get random records from ActiveRecord. For now it supports only PostgreSQL.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add active_record_random
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install active_record_random
```

## Usage

Just call `random` on your ActiveRecord model and enjoy:

```ruby
User.random
# => [#<User id: 1, name: "John", ...>]
```

You can also pass precision to `random` method:

```ruby
User.random(0.1)
# => [#<User id: 1, name: "Nikolas", ...>]
```

Combine with other ActiveRecord methods? No problem:

```ruby
User.where(age: 18..30).random(0.1).limit(10)
# => [#<User id: 1, name: "Nikolas", ...>, #<User id: 2, name: "John", ...>, ...]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/the-rubies-way/active_record_random. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/the-rubies-way/active_record_random/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord::Random project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/the-rubies-way/active_record_random/blob/master/CODE_OF_CONDUCT.md).
