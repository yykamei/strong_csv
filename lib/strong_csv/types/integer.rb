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
          ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.integer.constraint_error", value: value.inspect, default: :"_strong_csv.integer.constraint_error")])
        end
      rescue ArgumentError, TypeError
        ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.integer.cant_be_casted", value: value.inspect, default: :"_strong_csv.integer.cant_be_casted")])
      end
    end
  end
end
