# frozen_string_literal: true

class StrongCSV
  # Let is a class that is used to define types for columns.
  class Let
    attr_reader :types, :headers

    def initialize
      @types = {}
      @headers = false
    end

    # @param name [String, Symbol, Integer]
    # @param type [StrongCSV::Type::Base]
    # @param types [Array<StrongCSV::Type::Base>]
    def let(name, type, *types)
      type = types.empty? ? type : Types::Union.new(type, *types)
      case name
      when Integer
        @types[name] = type
      when String, Symbol
        @types[name.to_sym] = type
      else
        raise TypeError, "Invalid type specified for `name`. `name` must be String, Symbol, or Integer: #{name.inspect}"
      end
      validate_columns
    end

    def integer
      Types::Integer.new
    end

    def boolean
      Types::Boolean.new
    end

    private

    def validate_columns
      if @types.keys.all? { |k| k.is_a?(Integer) }
        @headers = false
      elsif @types.keys.all? { |k| k.is_a?(Symbol) }
        @headers = true
      else
        raise ArgumentError, "`types` cannot be mixed with Integer and Symbol keys: #{@types.keys.inspect}"
      end
    end
  end
end
