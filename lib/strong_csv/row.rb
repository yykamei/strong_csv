# frozen_string_literal: true

class StrongCSV
  # Row is a representation of a row in a CSV file, which has casted values with specified types.
  class Row
    extend Forwardable

    def_delegators :@values, :[], :fetch

    # @return [Hash]
    attr_reader :errors

    # @return [Integer]
    attr_reader :lineno

    # @param row [Array<String>, CSV::Row]
    # @param types [Hash]
    # @param lineno [Integer]
    def initialize(row:, types:, lineno:)
      @values = {}
      @errors = {}
      @lineno = lineno
      types.each do |key, type|
        value_result = type.cast(row[key])
        @values[key] = value_result.value
        @errors[key] = value_result.error_message unless value_result.success?
      end
    end

    def valid?
      @errors.empty?
    end
  end
end
