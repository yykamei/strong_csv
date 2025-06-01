# frozen_string_literal: true

class StrongCSV # rubocop:disable Style/Documentation
  using Types::Literal

  # TypeWrapper holds the `type` along with `name` and `block`. It might be useful to store metadata for the type,
  # such as `error_message`.
  #
  # @!attribute name
  #   @return [Symbol, Integer] The name for the type. This is the CSV header name. If the CSV does not have its header, Integer should be set.
  # @!attribute type
  #   @return [StrongCSV::Types::Base]
  # @!attribute error_message
  #   @return [String, nil] The error message returned if #cast fails. If omitted, the default error message will be used.
  # @!attribute block
  #   @return [Proc]
  TypeWrapper = Struct.new(:name, :type, :error_message, :block, keyword_init: true) do
    def cast(value)
      value_result = type.cast(value)
      casted = block && value_result.success? ? block.call(value_result.value) : value_result.value
      error = if value_result.success?
                nil
              else
                error_message ? [error_message] : value_result.error_messages
              end

      [casted, error]
    end
  end
end
