require "active_support"
require "active_support/core_ext"

require "active_record_random/adapters/active_record/base"

ActiveSupport.on_load(:active_record) do
  extend ActiveRecordRandom::Adapters::ActiveRecord::Base
end
