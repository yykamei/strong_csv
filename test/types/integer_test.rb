# frozen_string_literal: true

require_relative "../test_helper"

class TypesIntegerTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Integer.new.cast("-1")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal(-1, value_result.value)
  end

  def test_cast_with_error
    value_result = StrongCSV::Types::Integer.new.cast("1.3")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "1.3", value_result.value
    assert_equal '`"1.3"` can\'t be casted to Integer', value_result.error_message
  end

  def test_cast_with_nil_error
    value_result = StrongCSV::Types::Integer.new.cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal nil, value_result.value
    assert_equal "`nil` can't be casted to Integer", value_result.error_message
  end

  def test_initialize_without_headers
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let 0, int
    end
    strong_csv.parse(<<~CSV)
      40
    CSV
  end

  def test_initialize_with_headers
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id
      4,5,6
    CSV
  end

  # TODO: These test cases should be moved to separate files
  def test_int_with_negative_value
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id
      -4
    CSV
  end

  def test_int_with_hex_value
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id
      0x12
    CSV
  end

  def test_int_with_octal_value
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id
      0o12
    CSV
  end

  def test_int_with_float_value
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id
      4.5
    CSV
  end

  def test_int_with_non_numeric_value
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id
      abc
    CSV
  end

  def test_int_with_null
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id,
      3,
      ,
    CSV
  end

  def test_int_with_blank_value
    skip "#parse is not implemented"

    strong_csv = StrongCSV.new do
      let :id, int
    end
    strong_csv.parse(<<~CSV)
      id,
      3,
      " "
    CSV
  end
end
