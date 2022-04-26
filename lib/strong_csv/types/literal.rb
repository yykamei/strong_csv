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
            ValueResult.new(original_value: value, error_message: "`#{inspect}` is expected, but `#{int}` was given.")
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_message: "`#{value.inspect}` can't be casted to Integer")
        end
      end
    end
  end
end
