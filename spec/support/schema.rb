require "active_record"

case ENV["DB"].try(:downcase)
when "mysql", "mysql2"
  # To test with MySQL: `DB=mysql bundle exec rake spec`
  ActiveRecord::Base.establish_connection(
    adapter: "mysql2",
    database: "random_rails_test",
    username: ENV.fetch("MYSQL_USERNAME") { "root" },
    password: ENV.fetch("MYSQL_PASSWORD") { "" },
    encoding: "utf8"
  )
when "pg", "postgres", "postgresql"
  # To test with PostgreSQL: `DB=postgresql bundle exec rake spec`
  ActiveRecord::Base.establish_connection(
    adapter: "postgresql",
    database: "random_rails_test",
    username: ENV.fetch("DATABASE_USERNAME") { "postgres" },
    password: ENV.fetch("DATABASE_PASSWORD") { "" },
    host: ENV.fetch("DATABASE_HOST") { "localhost" },
    min_messages: "warning"
  )
else
  # Otherwise, assume SQLite3: `bundle exec rake spec`
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ":memory:"
  )
end

# This is just a test app with no sensitive data. In general, end users should
# explicitly authorize each model, but this shows a way to configure the
# unrestricted default behavior of an random-rails gem.
#
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Person < ApplicationRecord
end

module Schema
  def self.create
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define do
      create_table :people, force: true do |t|
        t.string :name
        t.timestamps null: false
      end
    end

    10.times do
      Person.create(name: Faker::Name.name)
    end
  end
end
