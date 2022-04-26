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
    assert_nil value_result.value
    assert_equal "`nil` can't be casted to Integer", value_result.error_message
  end

  def test_initialize_without_headers
    strong_csv = StrongCSV.new do
      let 0, integer
    end
    strong_csv.parse("40") do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal 40, row[0]
    end
  end

  def test_initialize_with_headers
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    data = <<~CSV
      id
      4,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal 4, row[:id]
    end
  end

  def test_int_with_negative_value
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    data = <<~CSV
      id
      -4
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal(-4, row[:id])
    end
  end

  def test_int_with_hex_value
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    result = strong_csv.parse(<<~CSV)
      id
      0x12
      123
    CSV
    assert result.all?(&:valid?)
    assert_equal([0x12, 123], result.map { |row| row[:id] })
  end

  def test_int_with_octal_value
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    result = strong_csv.parse(<<~CSV)
      id
      0o12
    CSV
    assert result.all?(&:valid?)
    assert_equal([0o12], result.map { |row| row[:id] })
  end

  def test_int_with_float_value
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    result = strong_csv.parse(<<~CSV)
      id
      4.5
    CSV
    refute result.all?(&:valid?)
    assert_equal(["4.5"], result.map { |row| row[:id] })
  end

  def test_int_with_non_numeric_value
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    result = strong_csv.parse(<<~CSV)
      id
      abc
    CSV
    refute result.all?(&:valid?)
    assert_equal(["abc"], result.map { |row| row[:id] })
  end

  def test_int_with_null
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_equal([3, nil], result.map { |row| row[:id] })
  end

  def test_int_with_blank_value
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      " "
    CSV
    refute result.all?(&:valid?)
    assert_equal([3, " "], result.map { |row| row[:id] })
  end
end
