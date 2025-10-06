# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)
require "random-rails/version"

Gem::Specification.new do |spec|
  spec.name    = "random-rails"
  spec.version = RandomRails::VERSION
  spec.authors = ["loqimean"]
  spec.email   = ["vanuha277@gmail.com"]

  spec.summary               = "Awesome gem to get random records from database."
  spec.description           = "The easiest way to get random records from database with best performance that you ever seen."
  spec.homepage              = "https://github.com/the-rubies-way/random-rails"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?("bin/", "test/", "spec/", "features/", ".git", ".circleci", "appveyor")
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # **********************************
  # * Dependencies
  spec.add_runtime_dependency "activerecord", ">= 4.0", "< 8.1"
  spec.add_runtime_dependency "activesupport", ">= 6.1.5", "< 8.1"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0.0"
  spec.add_development_dependency "standard", "~> 1.37.0"
  spec.add_development_dependency "rubocop", "~> 1.64.0"
  spec.add_development_dependency "rubocop-performance", "~> 1.21.0"
  spec.add_development_dependency "standard-performance", "~> 1.4.0"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
  spec.add_development_dependency "pry", "~> 0.14.2"
  spec.add_development_dependency "sqlite3", "~> 1.6"
  spec.add_development_dependency "pg", "~> 1.5"
  spec.add_development_dependency "mysql2", "~> 0.5.5"
  spec.add_development_dependency "faker", "~> 3.2"
  spec.add_development_dependency "mutex_m"
  spec.add_development_dependency "bigdecimal"

  spec.post_install_message = <<~MSG

    ===================================================================
    Thanks for installing random-rails!

    => For usage examples and documentation, please visit:
      https://github.com/the-rubies-way/random-rails#examples

    => If you find this gem useful, please consider starring the repository:
      https://github.com/the-rubies-way/random-rails
    ===================================================================

  MSG
end
