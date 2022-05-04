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
        ValueResult.new(original_value: value, error_messages: [I18n.t("strong_csv.float.cant_be_casted", value: value.inspect, default: :"_strong_csv.float.cant_be_casted")])
      end
    end
  end
end
