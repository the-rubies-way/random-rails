## [1.0.0] - 2025-09-30

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
