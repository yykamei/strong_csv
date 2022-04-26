# frozen_string_literal: true

class StrongCSV
  module Types
    # Integer type
    class Integer < Base
      # @todo Use :exception for Integer after we drop the support of Ruby 2.5
      def cast(value)
        ValueResult.new(value: Integer(value), original_value: value)
      rescue ArgumentError
        ValueResult.new(original_value: value, error_message: "`#{value.inspect}` can't be casted to Integer")
      end
    end
  end
end
