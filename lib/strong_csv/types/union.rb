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
        results = @types.map { |type| type.cast(value) }
        results.find(&:success?) || results.reduce do |memo, result|
          memo.error_messages.concat(result.error_messages).uniq!
          memo
        end
      end
    end
  end
end
