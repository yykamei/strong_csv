# frozen_string_literal: true

require_relative "../test_helper"

class LiteralFloatTest < Minitest::Test
  using StrongCSV::Types::Literal

  def test_cast
    value_result = 123.3.cast("123.3")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_in_delta(123.3, value_result.value)
  end

  def test_cast_unexpected_value
    value_result = 8.0.cast("13")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "13", value_result.value
    assert_equal ["`8.0` is expected, but `13.0` was given"], value_result.error_messages
  end

  def test_cast_nil
    value_result = 31.0.cast(nil)

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Float"], value_result.error_messages
  end

  def test_initialize_without_headers
    strong_csv = StrongCSV.new do
      let 0, 40.0
    end
    strong_csv.parse("40.0") do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta(40.0, row[0])
    end
  end

  def test_initialize_with_headers
    strong_csv = StrongCSV.new do
      let :id, 4.1
    end
    data = <<~CSV
      id
      4.1,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta(4.1, row[:id])
    end
  end

  def test_int_with_negative_value
    strong_csv = StrongCSV.new do
      let :id, -4.2
    end
    data = <<~CSV
      id
      -4.2
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta(-4.2, row[:id])
    end
  end

  def test_int_with_float_value
    strong_csv = StrongCSV.new do
      let :id, 80.0
    end
    result = strong_csv.parse(<<~CSV)
      id
      80
    CSV
    assert result.all?(&:valid?)
    assert_equal([80.0], result.map { |row| row[:id] })
  end

  def test_int_with_non_numeric_value
    strong_csv = StrongCSV.new do
      let :id, 80.0
    end
    result = strong_csv.parse(<<~CSV)
      id
      abc
    CSV
    refute result.all?(&:valid?)
    assert_equal(["abc"], result.map { |row| row[:id] })
    assert_equal([["`\"abc\"` can't be casted to Float"]], result.map { |row| row.errors[:id] })
  end

  def test_int_with_null
    strong_csv = StrongCSV.new do
      let :id, 80.0
    end
    result = strong_csv.parse(<<~CSV)
      id,
      80,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_equal([80.0, nil], result.map { |row| row[:id] })
    assert_equal([nil, ["`nil` can't be casted to Float"]], result.map { |row| row.errors[:id] })
  end

  def test_int_with_blank_value
    strong_csv = StrongCSV.new do
      let :id, 80.0
    end
    result = strong_csv.parse(<<~CSV)
      id,
      80,
      " "
    CSV
    refute result.all?(&:valid?)
    assert_equal([80.0, " "], result.map { |row| row[:id] })
    assert_equal([nil, ["`\" \"` can't be casted to Float"]], result.map { |row| row.errors[:id] })
  end
end
