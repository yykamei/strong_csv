# frozen_string_literal: true

class StrongCSV
  module Types
    # Union type is a type that combine multiple types.
    class Union < Base
      using Types::Literal

      # @param left [Base]
      # @param right [Base]
      def initialize(left, right)
        super()
        @left = left
        @right = right
      end

      # @param value [Object] Value to be casted to Integer
      # @return [ValueResult]
      def cast(value)
        left_result = @left.cast(value)
        return left_result if left_result.success?

        right_result = @right.cast(value)
        right_result.success? ? right_result : left_result.tap { |l| l.error_messages.concat(right_result.error_messages).uniq! }
      end
    end
  end
end
