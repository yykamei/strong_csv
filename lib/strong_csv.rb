# frozen_string_literal: true

require "csv"

require_relative "strong_csv/version"
require_relative "strong_csv/let"

# The top-level namespace for the strong_csv gem.
class StrongCSV
  class Error < StandardError; end

  def initialize(&block)
    @let = Let.new
    @let.instance_eval(&block) if block_given?
  end
end
