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
        return ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.string.cant_be_casted", value: value.inspect, default: :"_strong_csv.string.cant_be_casted")]) if value.nil?

        casted = String(value)
        if @within && !@within.cover?(casted.size)
          ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.string.out_of_range", value: value.inspect, range: @within.inspect, default: :"_strong_csv.string.out_of_range")])
        else
          ValueResult.new(value: casted, original_value: value)
        end
      end
    end
  end
end
