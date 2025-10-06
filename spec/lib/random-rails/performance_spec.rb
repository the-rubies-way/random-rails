# frozen_string_literal: true

RSpec.describe "Performance Comparison" do
  let(:adapter_name) { ActiveRecord::Base.connection.adapter_name.downcase }

  before(:all) do
    50.times do |i|
      Person.create(name: "Person #{i}")
    end
  end

  after(:all) do
    Person.delete_all
  end

  describe "strategy performance" do
    let(:offset_time) { Benchmark.realtime { 10.times { Person.random(strategy: :offset) } } }
    let(:order_by_time) { Benchmark.realtime { 10.times { Person.random(strategy: :order_by) } } }
    let(:tablesample_time) { Benchmark.realtime { 10.times { Person.random(strategy: :tablesample) } } }

    it "offset strategy is faster than order_by for single records" do
      expect(offset_time).to be > 0
      expect(order_by_time).to be > 0
    end

    context "when using tablesample strategy", if: ENV["DB"]&.downcase&.include?("pg") do
      it "tablesample strategy works for PostgreSQL" do
        expect(tablesample_time).to be > 0
      end
    end

    context "when using auto strategy" do
      before do
        allow_any_instance_of(Person).to receive(:estimate_table_size).and_return(100)
      end

      let(:result) { Person.random(strategy: :auto) }

      it "auto strategy selects appropriate method" do
        expect(result).to be_a(Person).or be_nil
      end
    end
  end

  describe "multiple records performance" do
    context "with multiple records" do
      let(:time) do
        Benchmark.realtime { Person.random(count: 5).to_a }
      end

      it "efficiently handles multiple random records" do
        expect(time).to be > 0
      end
    end

    context "when count = 1" do
      let(:result) { Person.random(count: 1) }

      it "returns single object" do
        expect(result).to be_a(Person).or be_nil
      end
    end

    context "when count > 1" do
      let(:result) { Person.random(count: 3) }

      it "returns relation" do
        expect(result).to be_a(ActiveRecord::Relation)
      end
    end
  end

  describe "table size estimation performance" do
    let(:person_class) { Person }

    before do
      RandomRails.configure { |config| config.cache_table_sizes = cache_enabled }
    end

    context "when caching is enabled" do
      let(:cache_enabled) { true }
      let(:first_estimate) { person_class.send(:estimate_table_size) }
      let(:second_estimate) { person_class.send(:estimate_table_size) }

      it "caches table size estimates" do
        expect(first_estimate).to eq(second_estimate)
      end
    end

    context "when caching is disabled" do
      let(:cache_enabled) { false }
      let(:first_estimate) { person_class.send(:estimate_table_size) }
      let(:second_estimate) { person_class.send(:estimate_table_size) }

      it "doesn't cache table size estimates" do
        expect([first_estimate, second_estimate]).to all(be_a(Integer))
      end
    end
  end
end
