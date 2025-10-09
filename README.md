[![lint](https://github.com/the-rubies-way/random-rails/actions/workflows/linter.yml/badge.svg)](https://github.com/the-rubies-way/random-rails/actions/workflows/linter.yml)
[![test](https://github.com/the-rubies-way/random-rails/actions/workflows/test.yml/badge.svg)](https://github.com/the-rubies-way/random-rails/actions/workflows/test.yml)
[![Gem Version](https://img.shields.io/gem/v/random-rails)](https://rubygems.org/gems/random-rails)

# RandomRails

🚀 The most performant way to get random records from ActiveRecord. Supports **PostgreSQL**, **MySQL**, and **SQLite** with intelligent strategy selection to replace slow `ORDER BY RANDOM()` queries.

## Why RandomRails?

Traditional `ORDER BY RANDOM()` queries become extremely slow on large tables because they require sorting the entire dataset. RandomRails solves this by using:

- **TABLESAMPLE BERNOULLI** for PostgreSQL (ultra-fast on large tables)
- **Efficient offset-based sampling** for all databases
- **Intelligent strategy selection** based on table size and database type
- **Configurable sampling methods** for different use cases

## Performance Comparison

Real-world benchmark results comparing RandomRails with traditional methods (10 iterations each):

| Sample Size     | `ORDER BY RANDOM()` | `User.random()` | `User.sample()` | Performance Gain        |
| --------------- | --------------------- | ----------------- | ----------------- | ----------------------- |
| 1,000 users     | 3.8359s               | **0.2157s** | 347.1409s         | **17.79x faster** |
| 10,000 users    | 6.1273s               | **2.7313s** | 369.7583s         | **2.24x faster**  |
| 100,000 users   | 31.578s               | **3.6968s** | 369.4334s         | **8.54x faster**  |
| 1,000,000 users | 171.497s              | **5.3441s** | 373.6102s         | **32.09x faster** |

**Key Takeaways:**

- RandomRails consistently outperforms `ORDER BY RANDOM()` by 2-32x
- Performance advantage increases dramatically with table size
- Traditional `User.sample()` method performs poorly at scale

## Installation

Add to your Gemfile:

```ruby
gem "random-rails"
```

Or install directly:

```bash
gem install random-rails
```

## Examples

### Basic Usage

Get a single random record:

```ruby
User.random
# => #<User id: 42, name: "John", ...>
```

Get multiple random records:

```ruby
User.random(count: 5)
# => [#<User id: 1, ...>, #<User id: 15, ...>, ...]
```

Chain with other ActiveRecord methods:

```ruby
User.where(active: true).random(count: 3)
# => [#<User id: 8, active: true, ...>, ...]
```

### Advanced Usage

#### Sampling Strategies

RandomRails provides multiple sampling strategies:

```ruby
# Auto-select best strategy (default)
User.random(strategy: :auto)

# Force TABLESAMPLE (PostgreSQL only)
User.random(strategy: :tablesample, precision: 1.0)

# Use efficient offset-based sampling
User.random(strategy: :offset)

# Fallback to ORDER BY RANDOM()
User.random(strategy: :order_by)
```

#### Configuration

Configure RandomRails globally:

```ruby
# config/initializers/random_rails.rb
RandomRails.configure do |config|
  config.default_strategy = :auto         # Default sampling strategy
  config.tablesample_threshold = 10_000  # Use TABLESAMPLE for tables larger than this
  config.cache_table_sizes = true         # Cache table size estimates
  config.precision = 1.0                  # Default TABLESAMPLE precision
end
```

#### Database-Specific Features

##### PostgreSQL

- Uses `TABLESAMPLE BERNOULLI` for large tables (> 10k records by default)
- Falls back to offset method for smaller tables
- Fast table size estimation using `pg_class`

##### MySQL

- Uses efficient offset-based sampling
- Table size estimation via `information_schema`
- Fallback to `ORDER BY RAND()` when needed

##### SQLite

- Offset-based sampling for optimal performance
- Graceful handling of table size estimation
- Compatible with in-memory databases

## Benchmarks

RandomRails automatically selects the best strategy for your database and table size. The benchmarks above demonstrate real-world performance improvements across different table sizes, with RandomRails consistently delivering superior performance through intelligent strategy selection:

- **Small tables**: Uses efficient offset-based sampling
- **Large tables (PostgreSQL)**: Leverages `TABLESAMPLE BERNOULLI` for optimal performance
- **All databases**: Falls back to optimized methods when needed

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
