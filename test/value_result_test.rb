# frozen_string_literal: true

require_relative "test_helper"

class ValueResultTest < Minitest::Test
  def test_initialize
    value_result = StrongCSV::ValueResult.new(value: 123.3, original_value: "123.3")
    assert value_result.success?
    assert_equal 123.3, value_result.value
    assert_nil value_result.error_messages
  end

  def test_initialize_with_error
    value_result = StrongCSV::ValueResult.new(original_value: "123.3", error_messages: ["error"])
    refute value_result.success?
    assert_equal "123.3", value_result.value
    assert_equal ["error"], value_result.error_messages
  end
end
