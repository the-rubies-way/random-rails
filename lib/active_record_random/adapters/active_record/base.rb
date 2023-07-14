module ActiveRecordRandom
  module Adapters
    module ActiveRecord
      module Base
        def random(precision: 10)
          # TODO: use different ways to sample data depending on the database adapter
          from("#{table_name} TABLESAMPLE BERNOULLI(#{precision})").limit(1)
        end
      end
    end
  end
end
