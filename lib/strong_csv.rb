# frozen_string_literal: true

require "csv"
require "forwardable"
require "set"
require "time"
require "i18n"

require_relative "strong_csv/version"
require_relative "strong_csv/i18n"
require_relative "strong_csv/value_result"
require_relative "strong_csv/types/base"
require_relative "strong_csv/types/boolean"
require_relative "strong_csv/types/float"
require_relative "strong_csv/types/integer"
require_relative "strong_csv/types/literal"
require_relative "strong_csv/types/optional"
require_relative "strong_csv/types/string"
require_relative "strong_csv/types/time"
require_relative "strong_csv/types/union"
require_relative "strong_csv/let"
require_relative "strong_csv/row"

# The top-level namespace for the strong_csv gem.
class StrongCSV
  class Error < StandardError; end

  def initialize(&block)
    @let = Let.new
    @let.instance_eval(&block) if block_given?
  end

  # @param csv [String, IO]
  # @param options [Hash] CSV options for parsing.
  def parse(csv, **options)
    # NOTE: Some options are overridden here to ensure that StrongCSV can handle parsed values correctly.
    options.delete(:nil_value)
    options = options.merge(headers: @let.headers, header_converters: :symbol)
    csv = CSV.new(csv, **options)
    if block_given?
      csv.each do |row|
        yield Row.new(row: row, types: @let.types, lineno: csv.lineno)
      end
    else
      csv.each.map { |row| Row.new(row: row, types: @let.types, lineno: csv.lineno) }
    end
  end
end
