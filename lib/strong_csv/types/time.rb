# frozen_string_literal: true

class StrongCSV
  module Types
    # Time type
    class Time < Base
      # @param format [String] The format of #strptime
      def initialize(format: "%Y-%m-%d")
        raise ArgumentError, "`format` must be a String" unless format.is_a?(::String)

        super()
        @format = format
      end

      # @param value [Object] Value to be casted to Time
      # @return [ValueResult]
      def cast(value)
        return ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Time with the format `#{@format.inspect}`"]) if value.nil?

        ValueResult.new(value: ::Time.strptime(value.to_s, @format), original_value: value)
      rescue ArgumentError
        ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Time with the format `#{@format.inspect}`"])
      end
    end
  end
end
