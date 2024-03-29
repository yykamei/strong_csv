# frozen_string_literal: true

require "csv"
require "forwardable"
require "set"
require "time"

require_relative "strong_csv/version"
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
require_relative "strong_csv/type_wrapper"
require_relative "strong_csv/let"
require_relative "strong_csv/row"

# StrongCSV is a library for parsing CSV contents with type checking.
#
# @example
#   strong_csv = StrongCSV.new do
#     let :name, string(within: 1..255)
#     let :score, integer
#   end
#
#   result = strong_csv.parse(<<~CSV)
#     name,score
#     JJ,X
#     Tomo,23
#     Haru,9
#   CSV
#   result.map(&:valid?) # => [false, true, true]
#
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

    @let.pickers.each_value do |picker|
      picker.call(csv)
      csv.rewind
    end

    if block_given?
      csv.each do |row|
        yield Row.new(row: row, types: @let.types, lineno: csv.lineno)
      end
    else
      csv.map { |row| Row.new(row: row, types: @let.types, lineno: csv.lineno) }
    end
  end
end
