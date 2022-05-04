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
        return ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.time.cant_be_casted", value: value.inspect, time_format: @format.inspect, default: :"_strong_csv.time.cant_be_casted")]) if value.nil?

        ValueResult.new(value: ::Time.strptime(value.to_s, @format), original_value: value)
      rescue ArgumentError
        ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.time.cant_be_casted", value: value.inspect, time_format: @format.inspect, default: :"_strong_csv.time.cant_be_casted")])
      end
    end
  end
end
