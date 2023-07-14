# frozen_string_literal: true

require "faker"
require "simplecov"

SimpleCov.start
SimpleCov.minimum_coverage 100
SimpleCov.add_filter "/spec/"

require "random-rails"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    message = "Running ActiveRecordRandom specs with #{
      ActiveRecord::Base.connection.adapter_name
    }, Active Record #{::ActiveRecord::VERSION::STRING}, Arel #{Arel::VERSION} and Ruby #{RUBY_VERSION}"
    line    = "=" * message.length

    puts line, message, line

    Schema.create
  end
end
