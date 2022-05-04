# frozen_string_literal: true

class StrongCSV
  module Types
    # Literal is a module to collect all the literal types for CSV parsing.
    # This module is intended for refining built-in classes and provide `#cast` like `Base` class.
    module Literal
      refine ::Integer do
        # @param value [Object] Value to be casted to Integer
        # @return [ValueResult]
        def cast(value)
          int = Integer(value)
          if int == self
            ValueResult.new(value: int, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.integer.unexpected", value: int.inspect, expected: inspect, default: :"_strong_csv.literal.integer.unexpected")])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.integer.cant_be_casted", value: value.inspect, default: :"_strong_csv.literal.integer.cant_be_casted")])
        end
      end

      refine ::Float do
        # @param value [Object] Value to be casted to Float
        # @return [ValueResult]
        def cast(value)
          float = Float(value)
          if float == self
            ValueResult.new(value: float, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.float.unexpected", value: float.inspect, expected: inspect, default: :"_strong_csv.literal.float.unexpected")])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.float.cant_be_casted", value: value.inspect, default: :"_strong_csv.literal.float.cant_be_casted")])
        end
      end

      refine ::Range do
        # @param value [Object] Value to be casted to Range
        # @return [ValueResult]
        def cast(value)
          return ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.range.cant_be_casted", value: value.inspect, expected: inspect, default: :"_strong_csv.literal.range.cant_be_casted")]) if value.nil?

          casted = case self.begin
                   when ::Float
                     Float(value)
                   when ::Integer
                     Integer(value)
                   when ::String
                     value
                   else
                     raise TypeError, "#{self.begin.class} is not supported"
                   end
          if cover?(casted)
            ValueResult.new(value: casted, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.range.out_of_range", value: casted.inspect, range: inspect, default: :"_strong_csv.literal.range.out_of_range")])
          end
        rescue ArgumentError
          ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.range.cant_be_casted", value: value.inspect, expected: inspect, default: :"_strong_csv.literal.range.cant_be_casted")])
        end
      end

      refine ::String do
        # @param value [Object] Value to be casted to String
        # @return [ValueResult]
        def cast(value)
          if self == value
            ValueResult.new(value: self, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.literal.string.unexpected", value: value.inspect, expected: inspect, default: :"_strong_csv.literal.string.unexpected")])
          end
        end
      end
    end
  end
end
