# frozen_string_literal: true

class StrongCSV
  # Let is a class that is used to define types for columns.
  class Let
    # @return [Hash{Symbol => [Types::Base, Proc]}]
    attr_reader :types

    # @return [Boolean]
    attr_reader :headers

    # @return [Hash]
    attr_reader :pickers

    def initialize
      @types = []
      @headers = false
      @pickers = {}
      @picked = {}
    end

    # @param name [String, Symbol, Integer]
    # @param type [StrongCSV::Types::Base]
    # @param types [Array<StrongCSV::Types::Base>]
    def let(name, type, *types, error_message: nil, &block)
      type = Types::Union.new(type, *types) unless types.empty?
      case name
      when ::Integer
        @types << TypeWrapper.new(name: name, type: type, block: block, error_message: error_message)
      when ::String, ::Symbol
        @types << TypeWrapper.new(name: name.to_sym, type: type, block: block, error_message: error_message)
      else
        raise TypeError, "Invalid type specified for `name`. `name` must be String, Symbol, or Integer: #{name.inspect}"
      end
      validate_columns
    end

    # #pick is intended for defining a singleton method with `:as`.
    # This might be useful for the case where you want to receive IDs that are stored in a database,
    # and you want to make sure the IDs actually exist.
    #
    # @example
    #  pick :user_id, as: :user_ids do |user_ids|
    #    User.where(id: user_ids).ids
    #  end
    #
    # @param column [Symbol, Integer]
    # @param as [Symbol]
    # @yieldparam values [Array<String>] The values for the column. NOTE: This is an array of String, not casted values.
    def pick(column, as:, &block)
      define_singleton_method(as) do
        @picked[as]
      end
      @pickers[as] = lambda do |csv|
        @picked[as] = block.call(csv.map { |row| row[column] })
      end
    end

    # @param options [Hash] See `Types::Integer#initialize` for more details.
    def integer(**options)
      Types::Integer.new(**options)
    end

    # @param options [Hash] See `Types::Integer#initialize` for more details.
    def integer?(**options)
      optional(integer(**options))
    end

    def boolean
      Types::Boolean.new
    end

    def boolean?
      optional(boolean)
    end

    # @param options [Hash] See `Types::Float#initialize` for more details.
    def float(**options)
      Types::Float.new(**options)
    end

    # @param options [Hash] See `Types::Float#initialize` for more details.
    def float?(**options)
      optional(float(**options))
    end

    # @param options [Hash] See `Types::String#initialize` for more details.
    def string(**options)
      Types::String.new(**options)
    end

    # @param options [Hash] See `Types::String#initialize` for more details.
    def string?(**options)
      optional(string(**options))
    end

    # @param options [Hash] See `Types::Time#initialize` for more details.
    def time(**options)
      Types::Time.new(**options)
    end

    # @param options [Hash] See `Types::Time#initialize` for more details.
    def time?(**options)
      optional(time(**options))
    end

    # @param args [Array] See `Types::Optional#initialize` for more details.
    def optional(*args)
      Types::Optional.new(*args)
    end

    private

    def validate_columns
      if @types.all? { |t| t.name.is_a?(Integer) }
        @headers = false
      elsif @types.all? { |k| k.name.is_a?(Symbol) }
        @headers = true
      else
        raise ArgumentError, "`types` cannot be mixed with Integer and Symbol keys: #{@types.map(&:name).inspect}"
      end
    end
  end
end
