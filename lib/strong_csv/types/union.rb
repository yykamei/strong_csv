# frozen_string_literal: true

class StrongCSV
  module Types
    # Union type is a type that combine multiple types.
    class Union < Base
      using Types::Literal

      # @param type [Base]
      # @param types [Array<Base>]
      def initialize(type, *types)
        super()
        @types = [type, *types]
      end

      # @param value [Object] Value to be casted to Integer
      # @return [ValueResult]
      def cast(value)
        error_messages = nil
        @types.each do |type|
          result = type.cast(value)
          return result if result.success?

          error_messages = (error_messages || []).concat(result.error_messages).uniq
        end

        ValueResult.new(original_value: value, error_messages: error_messages)
      end
    end
  end
end
