# frozen_string_literal: true

class StrongCSV
  module Types
    # Integer type
    class Integer < Base
      DEFAULT_CONSTRAINT = ->(_) { true }
      private_constant :DEFAULT_CONSTRAINT

      # @param constraint [Proc]
      def initialize(constraint: DEFAULT_CONSTRAINT)
        super()
        @constraint = constraint
      end

      # @todo Use :exception for Integer after we drop the support of Ruby 2.5
      # @param value [Object] Value to be casted to Integer
      # @return [ValueResult]
      def cast(value)
        int = Integer(value)
        if @constraint.call(int)
          ValueResult.new(value: int, original_value: value)
        else
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` does not satisfy the specified constraint"])
        end
      rescue ArgumentError, TypeError
        ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Integer"])
      end
    end
  end
end
