# frozen_string_literal: true

require "active_record"

RSpec.describe ActiveRecord do
  before do
    stub_const("Dummy", Class.new(ActiveRecord::Base))
  end

  it { expect(Dummy).to respond_to(:random) }
end
