require "active_support/lazy_load_hooks"

require "random-rails/adapters/active_record/base"

ActiveSupport.on_load(:active_record) do
  extend RandomRails::Adapters::ActiveRecord::Base
end
