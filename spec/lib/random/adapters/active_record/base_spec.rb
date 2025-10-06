# frozen_string_literal: true

RSpec.describe RandomRails::Adapters::ActiveRecord::Base do
  let(:adapter_name) { ActiveRecord::Base.connection.adapter_name.downcase }
  subject(:random_person) { Person.random }

  let(:random_person_count_1) { Person.random(count: 1) }
  let(:random_person_count_5) { Person.random(count: 5) }
  let(:random_person_count_2) { Person.random(count: 2) }
  let(:random_person_count_2_tablesample) { Person.random(count: 2, strategy: :tablesample) }
  let(:random_person_count_2_tablesample_precision) { Person.random(count: 2, strategy: :tablesample, precision: 5.0) }
  let(:random_person_count_2_auto) { Person.random(count: 2, strategy: :auto) }
  let(:random_person_count_2_order_by) { Person.random(count: 2, strategy: :order_by) }
  let(:random_person_offset) { Person.random(strategy: :offset) }
  let(:random_person_count_2_offset) { Person.random(count: 2, strategy: :offset) }
  let(:random_person_order_by) { Person.random(strategy: :order_by) }

  describe "#random" do
    it { expect(Person).to respond_to(:random) }

    context "with default parameters (count: 1)" do
      it "returns a single object" do
        expect(random_person).to be_a(Person).or be_nil
      end
    end

    context "with count parameter" do
      context "when count is 1" do
        it "returns a single object" do
          expect(random_person_count_1).to be_a(Person).or be_nil
        end
      end

      context "when count is greater than 1" do
        it "returns a relation" do
          expect(random_person_count_5).to be_a(ActiveRecord::Relation)
        end

        it "respects the count parameter" do
          expect(random_person_count_5.limit_value).to eq(5)
        end
      end
    end

    context "with PostgreSQL adapter", if: ENV["DB"]&.downcase&.include?("pg") do
      context "with tablesample strategy" do
        it "uses TABLESAMPLE BERNOULLI for multiple records" do
          expect(random_person_count_2_tablesample.to_sql).to include("TABLESAMPLE BERNOULLI")
        end

        it "uses custom precision for multiple records" do
          expect(random_person_count_2_tablesample_precision.to_sql).to include("TABLESAMPLE BERNOULLI(5.0)")
        end
      end

      context "with auto strategy on small table" do
        before { allow(Person).to receive(:estimate_table_size).and_return(100) }

        it "uses offset strategy for small tables with multiple records" do
          expect(random_person_count_2_auto.to_sql).to include("OFFSET")
        end
      end

      context "with auto strategy on large table" do
        before { allow(Person).to receive(:estimate_table_size).and_return(20_000) }

        it "uses tablesample strategy for large tables with multiple records" do
          expect(random_person_count_2_auto.to_sql).to include("TABLESAMPLE BERNOULLI")
        end
      end
    end

    context "with MySQL adapter", if: ENV["DB"]&.downcase&.include?("mysql") do
      it "returns single object by default" do
        expect(random_person).to be_a(Person).or be_nil
      end

      it "returns relation for multiple records" do
        expect(random_person_count_2).to be_a(ActiveRecord::Relation)
      end

      it "falls back to RAND() for order_by strategy" do
        expect(random_person_count_2_order_by.to_sql).to include("RAND()")
      end
    end

    context "with SQLite adapter", if: !ENV["DB"] || ENV["DB"]&.downcase&.include?("sqlite") do
      it "returns single object by default" do
        expect(random_person).to be_a(Person).or be_nil
      end

      it "returns relation for multiple records" do
        expect(random_person_count_2).to be_a(ActiveRecord::Relation)
      end

      it "falls back to RANDOM() for order_by strategy" do
        expect(random_person_count_2_order_by.to_sql).to include("RANDOM()")
      end
    end

    context "with offset strategy" do
      it "returns single object for count=1" do
        expect(random_person_offset).to be_a(Person).or be_nil
      end

      it "returns relation for count>1" do
        expect(random_person_count_2_offset).to be_a(ActiveRecord::Relation)
      end
    end

    context "with order_by strategy" do
      it "returns single object for count=1" do
        expect(random_person_order_by).to be_a(Person).or be_nil
      end

      it "returns relation for count>1" do
        expect(random_person_count_2_order_by).to be_a(ActiveRecord::Relation)
      end

      context "when requesting multiple records" do
        let(:sql) { random_person_count_2_order_by.to_sql }

        it "uses ORDER BY clause" do
          expect(sql).to match(/ORDER BY (RAND\(\)|RANDOM\(\))/i)
        end
      end
    end
  end

  describe "configuration" do
    around do |example|
      RandomRails.reset_configuration!
      example.run
      RandomRails.reset_configuration!
    end

    context "with configured default strategy" do
      before do
        RandomRails.configure do |config|
          config.default_strategy = :order_by
        end
      end

      it "works successfully" do
        expect(random_person).to be_a(Person).or be_nil
      end
    end

    context "with configured tablesample threshold" do
      before do
        RandomRails.configure do |config|
          config.tablesample_threshold = 5
        end

        allow(Person).to receive(:estimate_table_size).and_return(10)
      end

      it "uses configured tablesample threshold" do
        expect(Person.random(strategy: :auto)).to be_a(Person).or be_nil
      end
    end

    context "with configured precision" do
      before do
        RandomRails.configure do |config|
          config.precision = 2.5
        end
      end

      it "uses configured precision" do
        if adapter_name == "postgresql"
          expect(Person.random(count: 2, strategy: :tablesample).to_sql).to include("TABLESAMPLE BERNOULLI(2.5)")
        end
      end
    end
  end

  describe "error handling" do
    it "handles empty tables gracefully" do
      allow(Person).to receive(:estimate_table_size).and_return(0)

      expect(Person.random(count: 2).to_sql).to include("LIMIT")
    end

    it "falls back to count when estimate fails" do
      allow(Person.connection).to receive(:execute).and_raise(StandardError)

      expect { Person.send(:estimate_table_size) }.not_to raise_error
    end
  end
end
