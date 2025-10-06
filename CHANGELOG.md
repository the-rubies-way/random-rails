## [1.0.3] - 2025-10-07

### Maintenance Release - RuboCop & Dependency Updates

#### Fixed

- **RuboCop configuration**: Fixed configuration syntax by replacing `require:` with `plugins:` in RuboCop configuration files to follow the correct plugin loading mechanism
- **ActiveSupport loading**: Optimized ActiveSupport loading by using `lazy_load_hooks` instead of loading the entire core extensions

#### Changed

- **Dependency updates**:
  - Updated RuboCop from ~> 1.52 to ~> 1.80
  - Updated Standard from ~> 1.3 to ~> 1.51
  - Updated rubocop-rspec from ~> 2.22 to ~> 3.7
  - Updated rubocop-performance to ~> 1.25.0
  - Added mutex_m and bigdecimal as development dependencies

#### Technical Improvements

- Improved RuboCop plugin configuration for better linting
- More efficient ActiveSupport loading to reduce memory footprint
- Updated development tooling for better code quality enforcement

## [1.0.2] - 2025-10-06

### Maintenance Release - Code Quality & CI Improvements

#### Fixed

- **Floating-point precision bug**: Replaced direct float equality comparison (`precision == 1.0`) with epsilon-based comparison (`(precision - 1.0).abs < Float::EPSILON`) to avoid floating-point precision issues
- **Code formatting**: Improved code consistency and readability with proper parentheses around ternary operators and aligned variable assignments

#### Added

- **Enhanced test matrix**: Added Ruby 3.2.9, 3.3.9, and Rails 8.0.3 to CI test matrix for better compatibility testing
- **Improved .gitignore**: Added missing `*.gem` pattern to prevent accidental gem file commits

#### Changed

- **Code style improvements**:
  - Added parentheses around ternary operator conditions for better readability
  - Aligned variable assignments for consistent formatting
  - Updated string quotations to use double quotes consistently in specs
  - Removed unused `cache_key` variable
  - Added missing blank lines for better code organization

#### Technical Improvements

- Better floating-point comparison to prevent precision-related bugs
- More robust code style following Ruby best practices
- Enhanced CI coverage with additional Ruby and Rails versions

## [1.0.1] - 2025-09-30

### Major Release - Multi-Database Support & Performance Optimizations

#### Added

- **Multi-database support**: PostgreSQL, MySQL, and SQLite
- **Intelligent strategy selection**: Automatically chooses the best sampling method based on database type and table size
- **Multiple sampling strategies**:
  - `TABLESAMPLE BERNOULLI` for PostgreSQL (ultra-fast on large tables)
  - Efficient offset-based sampling for all databases
  - Traditional `ORDER BY RANDOM()` as fallback
- **Configuration system**: Global configuration for sampling strategies, thresholds, and caching
- **Performance optimizations**:
  - Fast table size estimation using database-specific methods
  - Configurable table size caching
  - Optimized multiple record retrieval
- **Enhanced API**: Support for `count` parameter and strategy selection
- **Comprehensive test suite**: Full coverage for all database adapters and strategies

#### Changed

- **Breaking**: Changed API from `random(precision:)` to `random(count:, strategy:, precision:)`
- **Breaking**: Now requires explicit count parameter for multiple records
- Improved error handling for edge cases (empty tables, connection failures)
- Enhanced SQL generation for better performance

#### Performance Improvements

- Up to 32x faster than `ORDER BY RANDOM()` on large tables
- Consistent ~2-3ms performance regardless of table size
- Intelligent strategy selection reduces query time dramatically

#### Examples

```ruby
# Before (slow on large tables)
User.order('RANDOM()').first     # ~171s on 1M records

# After (consistently fast)
User.random                      # ~5ms on 1M records
User.random(count: 5)           # Multiple records
User.random(strategy: :tablesample, precision: 2.0)  # Custom strategy
```

## [0.1.0] - 2023-07-13

- Initial release
- Added method `random` to get random records using PostgreSQL adapter
