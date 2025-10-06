# frozen_string_literal: true

require "active_record"

RSpec.describe ActiveRecord do
  before do
    stub_const("Dummy", Class.new(ActiveRecord::Base))
  end

  it { expect(Dummy).to respond_to(:random) }

  describe "return types" do
    subject { Person.random }

    it "returns single object by default" do
      expect(subject).to be_a(Person).or be_nil
    end

    it "returns single object when count is 1" do
      expect(subject).to be_a(Person).or be_nil
    end

    it "returns relation when count is greater than 1" do
      expect(Person.random(count: 3)).to be_a(ActiveRecord::Relation)
    end
  end
end
