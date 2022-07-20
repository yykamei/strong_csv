# frozen_string_literal: true

if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3")
  ENV["RBS_TEST_TARGET"] = "StrongCSV::*"
  require "rbs/test/setup"
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "strong_csv"

require "minitest/autorun"
