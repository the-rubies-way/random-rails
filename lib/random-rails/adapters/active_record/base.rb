require "active_record"
require "debug"
module RandomRails
  module Adapters
    module ActiveRecord
      module Base
        def random(precision: 10)
          # TODO: use different ways to sample data depending on the database adapter
          if connection.adapter_name == "postgresql"
            from("#{table_name} TABLESAMPLE BERNOULLI(#{precision})").limit(1)
          else
            # from("\"#{table_name}\" LIMIT 1 OFFSET (SELECT CAST(ROUND(RANDOM() * (SELECT COUNT(*) FROM \"#{table_name}\"))) AS INTEGER)")
            # =================
            # offset_value = connection.select_value("SELECT RANDOM() % MAX(id) FROM \"people\"").abs

            # offset(offset_value).limit(1)
            # =================
            # binding.irb
            from("\"#{table_name}\" LIMIT 1 OFFSET abs(random() % (SELECT count(*) FROM \"#{table_name}\"))")

            # SELECT "people".* FROM "people" LIMIT 1 OFFSET abs(random()%(SELECT count(*) FROM "people"));

            # from("\"#{table_name}\" OFFSET (SELECT CAST(ROUND(RANDOM() * (SELECT COUNT(*) FROM \"#{table_name}\")) AS INTEGER))")
            # people limit 1 offset (SELECT CAST(ROUND(RANDOM() * (SELECT COUNT(*) FROM "people")) AS INTEGER))
          end
        end
      end
    end
  end
end

# select * from people limit 1 offset (SELECT CAST(ROUND(RANDOM() * (SELECT COUNT(*) FROM "people")) AS INTEGER))



# SELECT ROUND(RANDOM() * (SELECT COUNT(*) FROM users)) FROM users LIMIT 1
