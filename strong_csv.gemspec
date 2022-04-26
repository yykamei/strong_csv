# frozen_string_literal: true

require_relative "lib/strong_csv/version"

Gem::Specification.new do |spec|
  spec.name = "strong_csv"
  spec.version = StrongCSV::VERSION
  spec.authors = ["Yutaka Kamei"]
  spec.email = ["kamei@yykamei.me"]

  spec.summary = "Type check CSV objects"
  spec.description = "strong_csv is a type checker for a CSV file. It lets developers declare types for each column to ensure all cells are satisfied with desired types."
  spec.homepage = "https://github.com/yykamei/strong_csv"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.5"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/yykamei/strong_csv/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "LICENSE", "README.md"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
end
