# frozen_string_literal: true

module RandomRails
  class Configuration
    attr_accessor :default_strategy, :tablesample_threshold, :cache_table_sizes, :precision

    def initialize
      @default_strategy = :auto
      @tablesample_threshold = 10_000 # Use TABLESAMPLE for tables larger than this
      @cache_table_sizes = true # Cache table size estimates
      @precision = 1.0 # Default precision for TABLESAMPLE
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
