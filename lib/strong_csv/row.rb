# frozen_string_literal: true

class StrongCSV
  # Row is a representation of a row in a CSV file, which has casted values with specified types.
  class Row
    extend Forwardable

    def_delegators :@values, :[], :fetch, :slice

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
      types.each do |wrapper|
        cell = row[wrapper.name]
        @values[wrapper.name], error = wrapper.cast(cell)
        @errors[wrapper.name] = error if error
      end
    end

    # It returns true if the row has no errors.
    #
    # @return [Boolean]
    def valid?
      @errors.empty?
    end
  end
end
