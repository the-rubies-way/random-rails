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

  spec.metadata["homepage_uri"]    = spec.homepage
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
  spec.add_dependency "activerecord", ">= 4.0"
  spec.add_dependency "activesupport", ">= 6.1.5"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rspec", "~> 2.22"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "rubocop", "~> 1.52"
  spec.add_development_dependency "rubocop-performance", "~> 1.18"
  spec.add_development_dependency "simplecov", "~> 0.22.0"
  spec.add_development_dependency "pry", "~> 0.14.2"
  spec.add_development_dependency "debug", ">= 1.0.0"
  spec.add_development_dependency "sqlite3", "~> 1.6"
  spec.add_development_dependency "pg", "~> 1.5"
  spec.add_development_dependency "mysql2", "~> 0.5.5"
  spec.add_development_dependency "faker", "~> 3.2"
end
