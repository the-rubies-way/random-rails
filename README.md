[![lint](https://github.com/the-rubies-way/random-rails/actions/workflows/linter.yml/badge.svg)](https://github.com/the-rubies-way/random-rails/actions/workflows/linter.yml)
[![test](https://github.com/the-rubies-way/random-rails/actions/workflows/test.yml/badge.svg)](https://github.com/the-rubies-way/random-rails/actions/workflows/test.yml)
[![Listed on OpenSource-Heroes.com](https://opensource-heroes.com/badge-v1.svg)](https://opensource-heroes.com/r/the-rubies-way/random-rails)

# RandomRails

The most perfomant way to get random records from ActiveRecord. In fact, it's the only way to get random records from ActiveRecord. For now, it supports only PostgreSQL.

## What about performance??

<img width="805" alt="The perfomance screenshot" src="https://github.com/the-rubies-way/random-rails/assets/49816584/f19c419a-f4a8-4ceb-95b4-d1f61b78fbd1">

## Installation

Install the gem and add it to the application's Gemfile by executing:

```bash
bundle add random-rails
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install random-rails
```

## Usage

Just call `random` on your ActiveRecord model and enjoy:

```ruby
User.random
# => [#<User id: 1, name: "John", ...>]
```

You can also pass precision to a `random` method:

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

Bug reports and pull requests are welcome on GitHub at https://github.com/the-rubies-way/random-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/the-rubies-way/random-rails/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord::Random project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/the-rubies-way/random-rails/blob/master/CODE_OF_CONDUCT.md).

## Thanks for your support!
[<img width="100" alt="RailsJazz" src="https://avatars.githubusercontent.com/u/104008706?s=200">](https://github.com/railsjazz)
