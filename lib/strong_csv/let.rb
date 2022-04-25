# frozen_string_literal: true

class StrongCSV
  # Let is a class that is used to define types for columns.
  class Let
    attr_reader :columns, :headers

    def initialize
      @columns = {}
      @headers = false
    end

    # @param name [String, Symbol, Integer]
    def let(name, type)
      case name
      when Integer
        @columns[name] = type
      when String, Symbol
        @columns[name.to_sym] = type
      else
        raise TypeError, "Invalid type specified for `name`. `name` must be String, Symbol, or Integer: #{name.inspect}"
      end
      validate_columns
    end

    private

    def validate_columns
      if @columns.keys.all? { |k| k.is_a?(Integer) }
        @headers = false
      elsif @columns.keys.all? { |k| k.is_a?(Symbol) }
        @headers = true
      else
        raise ArgumentError, "`columns` cannot be mixed with Integer and Symbol keys: #{@columns.keys.inspect}"
      end
    end
  end
end
