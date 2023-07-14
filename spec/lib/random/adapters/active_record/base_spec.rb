# frozen_string_literal: true

RSpec.describe RandomRails::Adapters::ActiveRecord::Base do
  describe "#random" do
    it { expect(Person).to respond_to(:random) }
    it { expect(Person.random).to be_a(ActiveRecord::Relation) }
    it { expect(Person.random.to_sql).to include("TABLESAMPLE BERNOULLI") }

    context "when precision is specified" do
      it { expect(Person.random(precision: 5).to_sql).to include("TABLESAMPLE BERNOULLI(5)") }
    end

    context "when limit is specified" do
      it { expect(Person.random.limit(5).to_sql).to include("LIMIT 5") }
    end
  end
end
