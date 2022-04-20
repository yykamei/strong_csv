# frozen_string_literal: true

require_relative "lib/strong_csv/version"

Gem::Specification.new do |spec|
  spec.name = "strong_csv"
  spec.version = StrongCSV::VERSION
  spec.authors = ["Yutaka Kamei"]
  spec.email = ["kamei@yykamei.me"]

  spec.summary = "Type check CSV objects"
  spec.description = "strong_csv is intended for checking the type of each CSV cell by declaring expected types."
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

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
