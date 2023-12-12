# frozen_string_literal: true
require "pry"
RSpec.describe RandomRails::Adapters::ActiveRecord::Base do
  describe "#random" do
    it { expect(Person).to respond_to(:random) }
    it { expect(Person.random).to be_a(ActiveRecord::Relation) }

    case ActiveRecord::Base.connection.adapter_name
    when "PostgreSQL"
      it { expect(Person.random.to_sql).to include("TABLESAMPLE BERNOULLI") }
    when "SQLite"
      it { expect(Person.random.to_sql).to include("OFFSET") }
    end

    context "when precision is specified" do
      case ActiveRecord::Base.connection.adapter_name
      when "PostgreSQL"
        it { expect(Person.random(precision: 5).to_sql).to include("TABLESAMPLE BERNOULLI(5)") }
      when "SQLite"
        it { expect(Person.random(precision: 5).to_sql).to include("OFFSET") }
      end

      # the main poblem is that calling `Person.random.inspect` will execute the query with "LIMIT ?" at the end that raises a syntax error
      it { binding.irb; expect(Person.random.inspect).to include(ActiveRecord::Relation.to_s) }
    end

    context "when limit is specified" do
      it { expect(Person.random.limit(5).to_sql).to include("LIMIT 5") }
    end
  end
end


# Person.from("
#   users
#   OFFSET ROUND(
#     RAND() * (
#       SELECT COUNT(*) FROM users
#     )
#   )
# ").limit(1).inspect


# offset = "SELECT ROUND(RAND() * (SELECT COUNT(*) FROM users))"

# "SELECT * FROM users OFFSET #{offset}"


# # * Correct offset
# # ROUND(RANDOM() * (SELECT COUNT(*) FROM people))

# offset = "ROUND(RANDOM() * (SELECT COUNT(*) FROM people))"

# sql = "SELECT * FROM people OFFSET #{offset}"

# Person.from("people OFFSET #{offset}")
