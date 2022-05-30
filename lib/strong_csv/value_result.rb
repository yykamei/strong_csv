# frozen_string_literal: true

class StrongCSV
  # ValueResult represents whether a CSV field is valid or not, and contains its casted value if it's valid.
  class ValueResult
    DEFAULT_VALUE = Object.new
    private_constant :DEFAULT_VALUE

    # @return [Array<String>, nil] The error messages for the field.
    attr_reader :error_messages

    def initialize(original_value:, value: DEFAULT_VALUE, error_messages: nil)
      @value = value
      @original_value = original_value
      @error_messages = error_messages
    end

    # @return [::Float, ::Integer, ::Object, ::String, ::Range, Boolean, ::Time, nil] The casted value if it's valid. Otherwise, returns the original value.
    def value
      success? ? @value : @original_value
    end

    # It returns true if the value is successfully casted.
    #
    # @return [Boolean]
    def success?
      @error_messages.nil?
    end
  end
end
