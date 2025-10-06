# frozen_string_literal: true

RSpec.describe "Database Adapter Integration" do
  let(:adapter_name) { ActiveRecord::Base.connection.adapter_name.downcase }

  describe "PostgreSQL specific features", if: ENV["DB"]&.downcase&.include?("pg") do
    it "supports TABLESAMPLE BERNOULLI" do
      expect { Person.random(strategy: :tablesample) }.not_to raise_error
    end

    it "uses RANDOM() for order_by strategy" do
      expect(Person.random(strategy: :order_by, count: 2).to_sql).to include("RANDOM()")
    end

    context "when estimating table size using pg_class" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return([{ 'reltuples' => '1000' }])
      end

      it "returns an integer" do
        expect(Person.send(:estimate_table_size)).to be_a(Integer)
      end
    end
  end

  describe "MySQL specific features", if: ENV["DB"]&.downcase&.include?("mysql") do
    it "does not support TABLESAMPLE" do
      # Should fall back to offset method
      expect(Person.random(strategy: :tablesample, count: 2).to_sql).to include("OFFSET")
    end

    it "uses RAND() for order_by strategy" do
      expect(Person.random(strategy: :order_by, count: 2).to_sql).to include("RAND()")
    end
    context "when estimating table size using information_schema" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return([[1000]])
      end

      it "returns an integer" do
        expect(Person.send(:estimate_table_size)).to be_a(Integer)
      end
    end
  end

  describe "SQLite specific features", if: !ENV["DB"] || ENV["DB"]&.downcase&.include?("sqlite") do
    subject(:result) { Person.random(strategy: :tablesample) }

    it "does not support TABLESAMPLE" do
      # Should fall back to offset method and return a single object
      expect(result).to be_a(Person).or be_nil
    end

    it "uses actual count for table size estimation" do
      expect(Person.send(:estimate_table_size)).to be_a(Integer)
    end

    it "uses RANDOM() for order_by strategy" do
      expect(Person.random(count: 2, strategy: :order_by).to_sql).to include("RANDOM()")
    end
  end

  describe "cross-database compatibility" do
    it "returns single object for count=1" do
      [:auto, :offset, :order_by, :tablesample].each do |strategy|
        expect(Person.random(strategy: strategy)).to be_a(Person).or be_nil
      end
    end

    it "returns ActiveRecord::Relation for count>1" do
      [:auto, :offset, :order_by, :tablesample].each do |strategy|
        expect(Person.random(count: 2, strategy: strategy)).to be_a(ActiveRecord::Relation)
      end
    end

    it "handles multiple record requests" do
      expect(Person.random(count: 3).limit_value).to eq(3)
    end

    it "handles edge cases gracefully" do
      # Very large count
      expect { Person.random(count: 1000) }.not_to raise_error

      # Normal operation
      expect(Person.random).to be_a(Person).or be_nil
    end
  end
end
