# frozen_string_literal: true

class StrongCSV
  module Types
    # String type
    class String < Base
      # @param within [Range, nil]
      def initialize(within: nil)
        raise ArgumentError, "`within` must be a Range" unless within.nil? || within.is_a?(Range)

        super()
        @within = within
      end

      # @param value [Object] Value to be casted to Boolean
      # @return [ValueResult]
      def cast(value)
        return ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to String"]) if value.nil?

        casted = String(value)
        if @within && !@within.cover?(casted.size)
          ValueResult.new(original_value: value, error_messages: ["The length of `#{value.inspect}` is out of range `#{@within.inspect}`"])
        else
          ValueResult.new(value: casted, original_value: value)
        end
      end
    end
  end
end
