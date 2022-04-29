# frozen_string_literal: true

class StrongCSV
  module Types
    # Optional type
    class Optional < Base
      using Types::Literal

      # @param type [Base]
      def initialize(type)
        super()
        @type = type
      end

      # @param value [Object]
      # @return [ValueResult]
      def cast(value)
        value.nil? ? ValueResult.new(value: nil, original_value: value) : @type.cast(value)
      end
    end
  end
end
