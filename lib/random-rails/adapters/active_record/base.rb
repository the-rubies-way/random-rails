module RandomRails
  module Adapters
    module ActiveRecord
      module Base
        # Main method to get random records efficiently
        #
        # @param count [Integer] Number of random records to return (default: 1)
        # @param strategy [Symbol] Sampling strategy (:auto, :tablesample, :offset, :order_by)
        # @param precision [Float] For TABLESAMPLE, percentage of table to sample (default: 1.0)
        # @return [ActiveRecord::Base, Array<ActiveRecord::Base>, ActiveRecord::Relation] Single object for count=1, relation otherwise
        def random(count: 1, strategy: :auto, precision: 1.0)
          strategy = determine_strategy(strategy)

          relation = case strategy
          when :tablesample
            tablesample_random(precision: precision, count: count)
          when :offset
            offset_random(count: count)
          when :order_by
            order_by_random(count: count)
          else
            # Fallback to offset method
            offset_random(count: count)
          end

          # Return single object for count=1, relation for count>1
          count == 1 ? relation.take : relation
        end

        private

        # Determine the best strategy based on database adapter and table size
        #
        # @param requested_strategy [Symbol] The strategy requested by the user
        # @return [Symbol] The strategy to use
        def determine_strategy(requested_strategy)
          requested_strategy = RandomRails.configuration.default_strategy if requested_strategy == :auto

          return requested_strategy unless requested_strategy == :auto

          adapter_name = connection.adapter_name.downcase

          case adapter_name
          when "postgresql"
            # PostgreSQL supports TABLESAMPLE for large tables, offset for smaller ones
            estimated_count = estimate_table_size

            estimated_count > RandomRails.configuration.tablesample_threshold ? :tablesample : :offset
          when "mysql", "mysql2"
            # MySQL doesn't have TABLESAMPLE, use offset method
            :offset
          when "sqlite"
            # SQLite doesn't have TABLESAMPLE, use offset method
            :offset
          else
            # Unknown adapter, use safest method
            :order_by
          end
        end

        # TABLESAMPLE method (PostgreSQL only)
        def tablesample_random(precision:, count:)
          if connection.adapter_name.downcase == "postgresql"
            # Use configured precision if not specified
            precision = RandomRails.configuration.precision if precision == 1.0

            from("#{table_name} TABLESAMPLE BERNOULLI(#{precision})").limit(count)
          else
            # Fallback for non-PostgreSQL databases
            offset_random(count: count)
          end
        end

        # Efficient offset-based random sampling
        def offset_random(count:)
          total_count = estimate_table_size

          return limit(count) if total_count == 0

          # Generate random offset, ensuring we always have an offset clause
          max_offset = [total_count - count, 0].max
          random_offset = max_offset > 0 ? rand(max_offset + 1) : 0

          # Always apply offset, even if it's 0, to ensure consistent SQL structure
          offset(random_offset).limit(count)
        end

        # Traditional ORDER BY RANDOM() method (fallback)
        def order_by_random(count:)
          case connection.adapter_name.downcase
          when "postgresql"
            order("RANDOM()").limit(count)
          when "mysql", "mysql2"
            order("RAND()").limit(count)
          when "sqlite"
            order("RANDOM()").limit(count)
          else
            order("RANDOM()").limit(count)
          end
        end

        # Estimate table size efficiently
        def estimate_table_size
          cache_key = "#{table_name}_count_estimate"

          if RandomRails.configuration.cache_table_sizes && @estimated_count
            return @estimated_count
          end

          estimated_count = begin
            case connection.adapter_name.downcase
            when "postgresql", "pg"
              # Use pg_class for fast estimate
              sql = "SELECT reltuples::INTEGER FROM pg_class WHERE relname = '#{table_name}'"
              result = connection.execute(sql).first

              result ? result["reltuples"].to_i : count
            when "mysql", "mysql2"
              # Use information_schema for fast estimate
              sql = "SELECT table_rows FROM information_schema.tables WHERE table_name = '#{table_name}'"
              result = connection.execute(sql).first

              result ? result[0].to_i : count
            else
              # Fallback to actual count for SQLite and others
              count
            end
          rescue
            # If estimation fails, use actual count
            count
          end

          @estimated_count = estimated_count if RandomRails.configuration.cache_table_sizes

          estimated_count
        end
      end
    end
  end
end
