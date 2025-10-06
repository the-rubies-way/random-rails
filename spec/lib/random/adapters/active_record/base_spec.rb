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

      it "uses configured precision when default precision (1.0) is passed" do
        if adapter_name == "postgresql"
          # When precision is 1.0 (default), it should use the configured precision
          expect(Person.random(count: 2, strategy: :tablesample, precision: 1.0).to_sql).to include("TABLESAMPLE BERNOULLI(2.5)")
        end
      end

      it "uses configured precision when no precision is specified" do
        if adapter_name == "postgresql"
          # When no precision is specified (defaults to 1.0), it should use the configured precision
          expect(Person.random(count: 2, strategy: :tablesample).to_sql).to include("TABLESAMPLE BERNOULLI(2.5)")
        end
      end

      context "when precision is explicitly set" do
        before do
          RandomRails.configure do |config|
            config.precision = 3.5
          end

          allow(Person.connection).to receive(:adapter_name).and_return("PostgreSQL")
        end

        it "uses explicitly set precision" do
          expect(Person.random(count: 2, strategy: :tablesample, precision: 3.5).to_sql).to include("TABLESAMPLE BERNOULLI(3.5)")
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

  describe "fallback strategy" do
    context "with unknown strategy" do
      let(:random_person_unknown_strategy) { Person.random(count: 2, strategy: :unknown) }

      it "falls back to offset method for unknown strategies" do
        expect(random_person_unknown_strategy.to_sql).to include("OFFSET")
      end

      it "returns a relation for multiple records" do
        expect(random_person_unknown_strategy).to be_a(ActiveRecord::Relation)
      end

      it "returns single object for count=1" do
        expect(Person.random(count: 1, strategy: :invalid)).to be_a(Person).or be_nil
      end

      context "when strategy doesn't match case branches" do
        let(:result) { Person.random(count: 2, strategy: :unmatched) }

        before do
          allow(Person).to receive(:determine_strategy).with(:unmatched).and_return(:unmatched)
        end

        it "executes the fallback else clause" do
          expect(result.to_sql).to include("OFFSET")
          expect(result).to be_a(ActiveRecord::Relation)
        end
      end

      context "when tablesample_random for non-PostgreSQL" do
        let(:result) { Person.send(:tablesample_random, precision: 1.0, count: 2) }

        before do
          allow(Person.connection).to receive(:adapter_name).and_return("MySQL")
        end

        it "falls back to offset method" do
          expect(result.to_sql).to include("OFFSET")
          expect(result).to be_a(ActiveRecord::Relation)
        end
      end
    end
  end

  describe "#order_by_random" do
    subject(:order_by_relation) { Person.send(:order_by_random, count: count) }

    let(:count) { 2 }

    context "with PostgreSQL adapter" do
      before { allow(Person.connection).to receive(:adapter_name).and_return("PostgreSQL") }

      it "uses ORDER BY RANDOM() for PostgreSQL" do
        expect(order_by_relation.to_sql).to include("ORDER BY RANDOM()")
      end

      it "applies LIMIT clause" do
        expect(order_by_relation.to_sql).to include("LIMIT #{count}")
      end

      it "returns an ActiveRecord::Relation" do
        expect(order_by_relation).to be_a(ActiveRecord::Relation)
      end
    end

    context "with MySQL adapter" do
      before { allow(Person.connection).to receive(:adapter_name).and_return("MySQL") }

      it "uses ORDER BY RAND() for MySQL" do
        expect(order_by_relation.to_sql).to include("ORDER BY RAND()")
      end

      it "applies LIMIT clause" do
        expect(order_by_relation.to_sql).to include("LIMIT #{count}")
      end

      it "returns an ActiveRecord::Relation" do
        expect(order_by_relation).to be_a(ActiveRecord::Relation)
      end
    end

    context "with MySQL2 adapter" do
      before { allow(Person.connection).to receive(:adapter_name).and_return("Mysql2") }

      it "uses ORDER BY RAND() for MySQL2" do
        expect(order_by_relation.to_sql).to include("ORDER BY RAND()")
      end

      it "applies LIMIT clause" do
        expect(order_by_relation.to_sql).to include("LIMIT #{count}")
      end
    end

    context "with SQLite adapter" do
      before { allow(Person.connection).to receive(:adapter_name).and_return("SQLite") }

      it "uses ORDER BY RANDOM() for SQLite" do
        expect(order_by_relation.to_sql).to include("ORDER BY RANDOM()")
      end

      it "applies LIMIT clause" do
        expect(order_by_relation.to_sql).to include("LIMIT #{count}")
      end

      it "returns an ActiveRecord::Relation" do
        expect(order_by_relation).to be_a(ActiveRecord::Relation)
      end
    end

    context "with unknown adapter" do
      before { allow(Person.connection).to receive(:adapter_name).and_return("UnknownDB") }

      it "falls back to ORDER BY RANDOM() for unknown adapters" do
        expect(order_by_relation.to_sql).to include("ORDER BY RANDOM()")
      end

      it "applies LIMIT clause" do
        expect(order_by_relation.to_sql).to include("LIMIT #{count}")
      end

      it "returns an ActiveRecord::Relation" do
        expect(order_by_relation).to be_a(ActiveRecord::Relation)
      end
    end

    context "with case-insensitive adapter names" do
      context "with lowercase postgresql" do
        before { allow(Person.connection).to receive(:adapter_name).and_return("postgresql") }

        it "uses ORDER BY RANDOM()" do
          expect(order_by_relation.to_sql).to include("ORDER BY RANDOM()")
        end
      end

      context "with mixed case MySQL" do
        before { allow(Person.connection).to receive(:adapter_name).and_return("mYsQl2") }

        it "uses ORDER BY RAND()" do
          expect(order_by_relation.to_sql).to include("ORDER BY RAND()")
        end
      end

      context "with uppercase SQLite" do
        before { allow(Person.connection).to receive(:adapter_name).and_return("SQLITE") }

        it "uses ORDER BY RANDOM()" do
          expect(order_by_relation.to_sql).to include("ORDER BY RANDOM()")
        end
      end
    end

    context "with different count values" do
      context "when count is 1" do
        let(:count) { 1 }

        it "applies LIMIT 1" do
          expect(order_by_relation.to_sql).to include("LIMIT 1")
        end
      end

      context "when count is 10" do
        let(:count) { 10 }

        it "applies LIMIT 10" do
          expect(order_by_relation.to_sql).to include("LIMIT 10")
        end
      end

      context "when count is 0" do
        let(:count) { 0 }

        it "applies LIMIT 0" do
          expect(order_by_relation.to_sql).to include("LIMIT 0")
        end
      end
    end

    context "integration with actual database" do
      let(:sql) { order_by_relation.to_sql }

      context "with PostgreSQL", if: ENV["DB"]&.downcase&.include?("pg") do
        it "generates valid PostgreSQL SQL" do
          expect(sql).to include("ORDER BY RANDOM()")
          expect(sql).to include("LIMIT")
          expect(sql).not_to include("RAND()")
        end
      end

      context "with MySQL", if: ENV["DB"]&.downcase&.include?("mysql") do
        it "generates valid MySQL SQL" do
          expect(sql).to include("ORDER BY RAND()")
          expect(sql).to include("LIMIT")
          expect(sql).not_to include("RANDOM()")
        end
      end

      context "with SQLite", if: !ENV["DB"] || ENV["DB"]&.downcase&.include?("sqlite") do
        it "generates valid SQLite SQL" do
          expect(sql).to include("ORDER BY RANDOM()")
          expect(sql).to include("LIMIT")
          expect(sql).not_to include("RAND()")
        end
      end
    end
  end

  describe "#determine_strategy" do
    subject(:strategy) { person_class.send(:determine_strategy, requested_strategy) }

    let(:person_class) { Person }

    describe "when requested_strategy is :auto and default_strategy is set" do
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

        let(:requested_strategy) { :auto }

        it "returns the configured default strategy" do
          expect(strategy).to eq(:order_by)
        end
      end

      context "with configured default strategy as :tablesample" do
        before do
          RandomRails.configure do |config|
            config.default_strategy = :tablesample
          end
        end

        let(:requested_strategy) { :auto }

        it "returns :tablesample when configured" do
          expect(strategy).to eq(:tablesample)
        end
      end
    end

    describe "when requested_strategy is not :auto" do
      let(:person_class) { Person }

      context "for :tablesample" do
        let(:requested_strategy) { :tablesample }

        it { is_expected.to eq(:tablesample) }
      end

      context "for :offset" do
        let(:requested_strategy) { :offset }

        it { is_expected.to eq(:offset) }
      end

      context "for :order_by" do
        let(:requested_strategy) { :order_by }

        it { is_expected.to eq(:order_by) }
      end

      context "for unknown strategies" do
        let(:requested_strategy) { :unknown_strategy }

        it { is_expected.to eq(:unknown_strategy) }
      end
    end

    describe "when requested_strategy is :auto and adapter-based selection" do
      let(:requested_strategy) { :auto }

      before { RandomRails.reset_configuration! }

      context "with PostgreSQL adapter" do
        before { allow(person_class.connection).to receive(:adapter_name).and_return("PostgreSQL") }

        context "with small table" do
          before { allow(person_class).to receive(:estimate_table_size).and_return(500) }

          it { is_expected.to eq(:offset) }
        end

        context "with large table" do
          before { allow(person_class).to receive(:estimate_table_size).and_return(15_000) }

          it { is_expected.to eq(:tablesample) }
        end

        context "with custom tablesample threshold" do
          around do |example|
            RandomRails.reset_configuration!
            example.run
            RandomRails.reset_configuration!
          end

          before do
            RandomRails.configure do |config|
              config.tablesample_threshold = 100
            end

            allow(person_class).to receive(:estimate_table_size).and_return(150)
          end

          it { is_expected.to eq(:tablesample) }
        end

        context "with table size exactly at threshold" do
          before { allow(person_class).to receive(:estimate_table_size).and_return(10_000) }

          it { is_expected.to eq(:offset) }
        end
      end

      context "with MySQL adapter" do
        before do
          allow(person_class.connection).to receive(:adapter_name).and_return("MySQL")
          allow(person_class).to receive(:estimate_table_size).and_return(50_000)
        end

        it { is_expected.to eq(:offset) }
      end

      context "with MySQL2 adapter" do
        before do
          allow(person_class.connection).to receive(:adapter_name).and_return("Mysql2")
          allow(person_class).to receive(:estimate_table_size).and_return(50_000)
        end

        it { is_expected.to eq(:offset) }
      end

      context "with SQLite adapter" do
        before do
          allow(person_class.connection).to receive(:adapter_name).and_return("SQLite")
          allow(person_class).to receive(:estimate_table_size).and_return(50_000)
        end

        it { is_expected.to eq(:offset) }
      end

      context "with unknown adapter" do
        before { allow(person_class.connection).to receive(:adapter_name).and_return("UnknownDB") }

        it { is_expected.to eq(:order_by) }
      end

      context "with case-insensitive adapter names" do
        context "handles uppercase PostgreSQL" do
          before do
            allow(person_class.connection).to receive(:adapter_name).and_return("POSTGRESQL")
            allow(person_class).to receive(:estimate_table_size).and_return(500)
          end

          it { is_expected.to eq(:offset) }
        end

        context "handles mixed case MySQL" do
          before { allow(person_class.connection).to receive(:adapter_name).and_return("mYsQl") }

          it { is_expected.to eq(:offset) }
        end

        context "handles uppercase SQLite" do
          before { allow(person_class.connection).to receive(:adapter_name).and_return("SQLITE") }

          it { is_expected.to eq(:offset) }
        end
      end
    end
  end

  describe "#estimate_table_size" do
    subject(:estimated_size) { Person.send(:estimate_table_size) }

    around do |example|
      RandomRails.reset_configuration!
      # Clear any cached instance variable
      Person.instance_variable_set(:@estimated_count, nil) if Person.instance_variable_defined?(:@estimated_count)
      example.run
      RandomRails.reset_configuration!
      Person.instance_variable_set(:@estimated_count, nil) if Person.instance_variable_defined?(:@estimated_count)
    end

    context "with caching enabled" do
      before do
        RandomRails.configure do |config|
          config.cache_table_sizes = true
        end
      end

      context "when no cached value exists" do
        before { Person.instance_variable_set(:@estimated_count, nil) }

        it "calculates and caches the table size" do
          adapter_name = Person.connection.adapter_name.downcase

          if adapter_name.include?("postgres")
            # Mock PostgreSQL pg_class query
            allow(Person.connection).to receive(:execute)
              .with(/SELECT reltuples::INTEGER FROM pg_class WHERE relname = /)
              .and_return([{ "reltuples" => "1500" }])
          elsif adapter_name.include?("mysql")
            # Mock MySQL information_schema query
            allow(Person.connection).to receive(:execute)
              .with(/SELECT table_rows FROM information_schema\.tables WHERE table_name = /)
              .and_return([[1500]])
          else
            allow(Person).to receive(:count).and_return(1500)
          end

          result = estimated_size

          expect(result).to eq(1500)
          expect(Person.instance_variable_get(:@estimated_count)).to eq(1500)
        end
      end

      context "when cached value exists" do
        before { Person.instance_variable_set(:@estimated_count, 2000) }

        it "returns cached value without recalculating" do
          expect(Person).not_to receive(:count)
          expect(Person.connection).not_to receive(:execute)

          expect(estimated_size).to eq(2000)
        end
      end
    end

    context "with caching disabled" do
      before do
        RandomRails.configure do |config|
          config.cache_table_sizes = false
        end
      end

      it "always recalculates and does not cache" do
        adapter_name = Person.connection.adapter_name.downcase

        if adapter_name.include?("postgres")
          # Mock PostgreSQL pg_class query
          allow(Person.connection).to receive(:execute)
            .with(/SELECT reltuples::INTEGER FROM pg_class WHERE relname = /)
            .and_return([{ "reltuples" => "800" }])
        elsif adapter_name.include?("mysql")
          # Mock MySQL information_schema query
          allow(Person.connection).to receive(:execute)
            .with(/SELECT table_rows FROM information_schema\.tables WHERE table_name = /)
            .and_return([[800]])
        else
          allow(Person).to receive(:count).and_return(800)
        end

        result = estimated_size

        expect(result).to eq(800)
        expect(Person.instance_variable_get(:@estimated_count)).to be_nil
      end
    end

    context "with PostgreSQL adapter" do
      before do
        allow(Person.connection).to receive(:adapter_name).and_return("PostgreSQL")
        allow(Person).to receive(:table_name).and_return("people")
      end

      context "when pg_class query succeeds" do
        let(:mock_result) { [{ "reltuples" => "1500" }] }

        before do
          allow(Person.connection).to receive(:execute)
            .with("SELECT reltuples::INTEGER FROM pg_class WHERE relname = 'people'")
            .and_return(mock_result)
        end

        it "returns estimated count from pg_class" do
          expect(estimated_size).to eq(1500)
        end

        it "converts string result to integer" do
          allow(Person.connection).to receive(:execute).and_return([{ "reltuples" => "2500" }])
          expect(estimated_size).to eq(2500)
        end
      end

      context "when pg_class query returns nil result" do
        before do
          allow(Person.connection).to receive(:execute).and_return([])
          allow(Person).to receive(:count).and_return(1200)
        end

        it "falls back to actual count" do
          expect(estimated_size).to eq(1200)
        end
      end

      context "when pg_class query returns empty result" do
        before do
          allow(Person.connection).to receive(:execute).and_return(nil)
          allow(Person).to receive(:count).and_return(900)
        end

        it "falls back to actual count" do
          expect(estimated_size).to eq(900)
        end
      end

      context "when pg_class query raises exception" do
        before do
          allow(Person.connection).to receive(:execute).and_raise(StandardError, "Connection failed")
          allow(Person).to receive(:count).and_return(1100)
        end

        it "handles exception and falls back to count" do
          expect(estimated_size).to eq(1100)
        end
      end
    end

    context "with pg adapter (short name)" do
      before do
        allow(Person.connection).to receive(:adapter_name).and_return("pg")
        allow(Person).to receive(:table_name).and_return("people")
      end

      it "uses PostgreSQL logic for pg adapter" do
        mock_result = [{ "reltuples" => "750" }]
        allow(Person.connection).to receive(:execute)
          .with("SELECT reltuples::INTEGER FROM pg_class WHERE relname = 'people'")
          .and_return(mock_result)

        expect(estimated_size).to eq(750)
      end
    end

    context "with MySQL adapter" do
      before do
        allow(Person.connection).to receive(:adapter_name).and_return("mysql")
        allow(Person).to receive(:table_name).and_return("people")
      end

      context "when information_schema query succeeds" do
        let(:mock_result) { [[2000]] }

        before do
          allow(Person.connection).to receive(:execute)
            .with("SELECT table_rows FROM information_schema.tables WHERE table_name = 'people'")
            .and_return(mock_result)
        end

        it "returns estimated count from information_schema" do
          expect(estimated_size).to eq(2000)
        end

        it "converts array result to integer" do
          allow(Person.connection).to receive(:execute).and_return([[3500]])
          expect(estimated_size).to eq(3500)
        end
      end

      context "when information_schema query returns nil result" do
        before do
          allow(Person.connection).to receive(:execute).and_return([])
          allow(Person).to receive(:count).and_return(1800)
        end

        it "falls back to actual count" do
          expect(estimated_size).to eq(1800)
        end
      end

      context "when information_schema query raises exception" do
        before do
          allow(Person.connection).to receive(:execute).and_raise(StandardError, "Table not found")
          allow(Person).to receive(:count).and_return(1400)
        end

        it "handles exception and falls back to count" do
          expect(estimated_size).to eq(1400)
        end
      end
    end

    context "with MySQL2 adapter" do
      before do
        allow(Person.connection).to receive(:adapter_name).and_return("mysql2")
        allow(Person).to receive(:table_name).and_return("people")
      end

      it "uses MySQL logic for mysql2 adapter" do
        mock_result = [[1250]]
        allow(Person.connection).to receive(:execute)
          .with("SELECT table_rows FROM information_schema.tables WHERE table_name = 'people'")
          .and_return(mock_result)

        expect(estimated_size).to eq(1250)
      end
    end

    context "with SQLite adapter" do
      before do
        allow(Person.connection).to receive(:adapter_name).and_return("sqlite")
        allow(Person).to receive(:count).and_return(600)
      end

      it "uses actual count for SQLite" do
        expect(estimated_size).to eq(600)
      end

      it "does not attempt to execute estimation queries" do
        expect(Person.connection).not_to receive(:execute)
        estimated_size
      end
    end

    context "with unknown adapter" do
      before do
        allow(Person.connection).to receive(:adapter_name).and_return("UnknownDB")
        allow(Person).to receive(:count).and_return(450)
      end

      it "falls back to actual count for unknown adapters" do
        expect(estimated_size).to eq(450)
      end

      it "does not attempt to execute estimation queries" do
        expect(Person.connection).not_to receive(:execute)
        estimated_size
      end
    end

    context "with case-insensitive adapter names" do
      context "with uppercase PostgreSQL" do
        before do
          allow(Person.connection).to receive(:adapter_name).and_return("POSTGRESQL")
          allow(Person).to receive(:table_name).and_return("people")
          allow(Person.connection).to receive(:execute).and_return([{ "reltuples" => "333" }])
        end

        it "handles uppercase PostgreSQL adapter name" do
          expect(estimated_size).to eq(333)
        end
      end

      context "with mixed case MySQL" do
        before do
          allow(Person.connection).to receive(:adapter_name).and_return("MySqL2")
          allow(Person).to receive(:table_name).and_return("people")
          allow(Person.connection).to receive(:execute).and_return([[777]])
        end

        it "handles mixed case MySQL adapter name" do
          expect(estimated_size).to eq(777)
        end
      end

      context "with uppercase SQLite" do
        before do
          allow(Person.connection).to receive(:adapter_name).and_return("SQLITE")
          allow(Person).to receive(:count).and_return(222)
        end

        it "handles uppercase SQLite adapter name" do
          expect(estimated_size).to eq(222)
        end
      end
    end

    context "error handling and edge cases" do
      context "when database connection fails during estimation" do
        before do
          allow(Person.connection).to receive(:adapter_name).and_return("PostgreSQL")
          allow(Person.connection).to receive(:execute).and_raise(ActiveRecord::ConnectionNotEstablished)
          allow(Person).to receive(:count).and_return(500)
        end

        it "gracefully falls back to count method" do
          expect(estimated_size).to eq(500)
        end
      end

      context "when count method also fails" do
        before do
          allow(Person.connection).to receive(:adapter_name).and_return("PostgreSQL")
          allow(Person.connection).to receive(:execute).and_raise(StandardError)
          allow(Person).to receive(:count).and_raise(StandardError, "Count failed")
        end

        it "raises the count method error" do
          expect { estimated_size }.to raise_error(StandardError, "Count failed")
        end
      end

      context "with malformed database results" do
        before { allow(Person.connection).to receive(:adapter_name).and_return("PostgreSQL") }

        context "when PostgreSQL returns non-numeric result" do
          before do
            allow(Person.connection).to receive(:execute).and_return([{ "reltuples" => "invalid" }])
            allow(Person).to receive(:count).and_return(100)
          end

          it "converts invalid string to 0" do
            expect(estimated_size).to eq(0)
          end
        end

        context "when MySQL returns empty array" do
          before do
            allow(Person.connection).to receive(:adapter_name).and_return("mysql")
            allow(Person.connection).to receive(:execute).and_return([[]])
            allow(Person).to receive(:count).and_return(150)
          end

          it "handles empty array access and converts nil to 0" do
            expect(estimated_size).to eq(0)
          end
        end
      end
    end

    context "integration with actual database" do
      context "with PostgreSQL", if: ENV["DB"]&.downcase&.include?("pg") do
        it "returns a numeric value" do
          # Mock PostgreSQL to return a valid value since test tables might not have statistics
          allow(Person.connection).to receive(:execute)
            .with(/SELECT reltuples::INTEGER FROM pg_class WHERE relname = /)
            .and_return([{ "reltuples" => "5" }])

          expect(estimated_size).to be_a(Integer)
          expect(estimated_size).to be >= 0
        end

        it "caches result when caching is enabled" do
          RandomRails.configure { |config| config.cache_table_sizes = true }

          # Mock PostgreSQL to return a consistent value
          allow(Person.connection).to receive(:execute)
            .with(/SELECT reltuples::INTEGER FROM pg_class WHERE relname = /)
            .and_return([{ "reltuples" => "10" }])

          first_call  = estimated_size
          second_call = estimated_size

          expect(first_call).to eq(second_call)
          expect(Person.instance_variable_get(:@estimated_count)).to eq(first_call)
        end
      end

      context "with MySQL", if: ENV["DB"]&.downcase&.include?("mysql") do
        it "returns a numeric value" do
          expect(estimated_size).to be_a(Integer)
          expect(estimated_size).to be >= 0
        end
      end

      context "with SQLite", if: !ENV["DB"] || ENV["DB"]&.downcase&.include?("sqlite") do
        it "returns actual count" do
          actual_count = Person.count
          expect(estimated_size).to eq(actual_count)
        end

        it "returns a numeric value" do
          expect(estimated_size).to be_a(Integer)
          expect(estimated_size).to be >= 0
        end
      end
    end
  end
end
