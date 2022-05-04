# frozen_string_literal: true

class StrongCSV
  module Types
    # Integer type
    class Integer < Base
      # @todo Use :exception for Integer after we drop the support of Ruby 2.5
      # @param value [Object] Value to be casted to Integer
      # @return [ValueResult]
      def cast(value)
        ValueResult.new(value: Integer(value), original_value: value)
      rescue ArgumentError, TypeError
        ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.integer.cant_be_casted", value: value.inspect, default: :"_strong_csv.integer.cant_be_casted")])
      end
    end
  end
end
