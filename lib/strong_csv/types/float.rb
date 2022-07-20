# frozen_string_literal: true

class StrongCSV
  module Types
    # Float type
    class Float < Base
      DEFAULT_CONSTRAINT = ->(_) { true }
      private_constant :DEFAULT_CONSTRAINT

      # @param constraint [Proc]
      def initialize(constraint: DEFAULT_CONSTRAINT)
        super()
        @constraint = constraint
      end

      # @todo Use :exception for Float after we drop the support of Ruby 2.5
      # @param value [Object] Value to be casted to Float
      # @return [ValueResult]
      def cast(value)
        float = Float(value)
        if @constraint.call(float)
          ValueResult.new(value: float, original_value: value)
        else
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` does not satisfy the specified constraint"])
        end
      rescue ArgumentError, TypeError
        ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Float"])
      end
    end
  end
end
