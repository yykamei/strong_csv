# frozen_string_literal: true

class StrongCSV
  module Types
    # Float type
    class Float < Base
      # @todo Use :exception for Float after we drop the support of Ruby 2.5
      # @param value [Object] Value to be casted to Float
      # @return [ValueResult]
      def cast(value)
        ValueResult.new(value: Float(value), original_value: value)
      rescue ArgumentError, TypeError
        ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Float"])
      end
    end
  end
end
