# frozen_string_literal: true

RSpec.describe RandomRails::Configuration do
  describe "default configuration" do
    let(:config) { described_class.new }

    it "has default strategy as auto" do
      expect(config.default_strategy).to eq(:auto)
    end

    it "has default tablesample threshold of 10,000" do
      expect(config.tablesample_threshold).to eq(10_000)
    end

    it "has cache_table_sizes enabled by default" do
      expect(config.cache_table_sizes).to be true
    end

    it "has default precision of 1.0" do
      expect(config.precision).to eq(1.0)
    end
  end

  describe "configuration" do
    around do |example|
      RandomRails.reset_configuration!
      example.run
      RandomRails.reset_configuration!
    end

    context "when configuring default strategy" do
      let(:strategy_value) { :tablesample }

      before do
        RandomRails.configure do |config|
          config.default_strategy = strategy_value
        end
      end

      it "allows configuring default strategy" do
        expect(RandomRails.configuration.default_strategy).to eq(strategy_value)
      end
    end

    context "when configuring tablesample threshold" do
      let(:threshold_value) { 5_000 }

      before do
        RandomRails.configure do |config|
          config.tablesample_threshold = threshold_value
        end
      end

      it "allows configuring tablesample threshold" do
        expect(RandomRails.configuration.tablesample_threshold).to eq(threshold_value)
      end
    end

    context "when configuring cache settings" do
      let(:cache_enabled) { false }

      before do
        RandomRails.configure do |config|
          config.cache_table_sizes = cache_enabled
        end
      end

      it "allows disabling cache" do
        expect(RandomRails.configuration.cache_table_sizes).to eq(cache_enabled)
      end
    end

    context "when configuring precision" do
      let(:precision_value) { 0.5 }

      before do
        RandomRails.configure do |config|
          config.precision = precision_value
        end
      end

      it "allows configuring precision" do
        expect(RandomRails.configuration.precision).to eq(precision_value)
      end
    end
  end

  describe ".reset_configuration!" do
    let(:custom_strategy) { :tablesample }
    let(:custom_threshold) { 5_000 }
    let(:default_strategy) { :auto }
    let(:default_threshold) { 10_000 }

    before do
      RandomRails.configure do |config|
        config.default_strategy = custom_strategy
        config.tablesample_threshold = custom_threshold
      end
    end

    it "resets to default configuration" do
      RandomRails.reset_configuration!

      expect(RandomRails.configuration.default_strategy).to eq(default_strategy)
      expect(RandomRails.configuration.tablesample_threshold).to eq(default_threshold)
    end
  end
end
