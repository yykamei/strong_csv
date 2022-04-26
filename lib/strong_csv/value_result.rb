# frozen_string_literal: true

class StrongCSV
  # ValueResult represents a CSV field is valid or not and contains its casted value if it's valid.
  class ValueResult
    DEFAULT_VALUE = Object.new
    private_constant :DEFAULT_VALUE

    # @return [String, nil] The error message for the field.
    attr_reader :error_message

    def initialize(original_value:, value: DEFAULT_VALUE, error_message: nil)
      @value = value
      @original_value = original_value
      @error_message = error_message
    end

    # @return [Object] The casted value if it's valid. Otherwise, returns the original value.
    def value
      success? ? @value : @original_value
    end

    # @return [Boolean]
    def success?
      @error_message.nil?
    end
  end
end
