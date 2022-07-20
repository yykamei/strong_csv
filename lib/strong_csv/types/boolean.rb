# frozen_string_literal: true

class StrongCSV
  module Types
    # Boolean type
    class Boolean < Base
      TRUE_VALUES = %w[true True TRUE].to_set.freeze
      FALSE_VALUES = %w[false False FALSE].to_set.freeze
      private_constant :TRUE_VALUES, :FALSE_VALUES

      # @param value [Object] Value to be casted to Boolean
      # @return [ValueResult]
      def cast(value)
        boolean = TRUE_VALUES.include?(value) ? true : nil
        return ValueResult.new(value: boolean, original_value: value) unless boolean.nil?

        boolean = FALSE_VALUES.include?(value) ? false : nil
        return ValueResult.new(value: boolean, original_value: value) unless boolean.nil?

        ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Boolean"])
      end
    end
  end
end
