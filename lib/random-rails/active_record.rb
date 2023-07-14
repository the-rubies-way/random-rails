require "active_support"
require "active_support/core_ext"

require "random-rails/adapters/active_record/base"

ActiveSupport.on_load(:active_record) do
  extend RandomRails::Adapters::ActiveRecord::Base
end
