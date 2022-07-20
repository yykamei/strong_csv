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
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{int.inspect}` was given"])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Integer"])
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
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{float.inspect}` was given"])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Float"])
        end
      end

      refine ::Range do
        # @param value [Object] Value to be casted to Range
        # @return [ValueResult]
        def cast(value)
          return ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to the beginning of `#{inspect}`"]) if value.nil?

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
            ValueResult.new(original_value: value, error_messages: ["`#{casted.inspect}` is not within `#{inspect}`"])
          end
        rescue ArgumentError
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to the beginning of `#{inspect}`"])
        end
      end

      refine ::String do
        # @param value [Object] Value to be casted to String
        # @return [ValueResult]
        def cast(value)
          if self == value
            ValueResult.new(value: self, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{value.inspect}` was given"])
          end
        end
      end

      refine ::Regexp do
        # @param value [Object] Value to be casted to String
        # @return [ValueResult]
        def cast(value)
          return ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to String"]) if value.nil?

          if self =~ value
            ValueResult.new(value: value, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` did not match `#{inspect}`"])
          end
        end
      end
    end
  end
end
