# frozen_string_literal: true

require_relative "../test_helper"

class LiteralRangeTest < Minitest::Test
  using StrongCSV::Types::Literal

  def test_cast_literal_range_with_integer
    value_result = (1...5).cast("4")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal 4, value_result.value
  end

  def test_cast_literal_range_with_float
    value_result = (-1.0...5).cast("-0.999")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal(-0.999, value_result.value)
  end

  def test_cast_literal_range_with_string
    value_result = ("a".."z").cast("z")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal "z", value_result.value
  end

  def test_cast_with_unexpected_value
    value_result = (1..34).cast("1.34")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "1.34", value_result.value
    assert_equal ["`\"1.34\"` can't be casted to the beginning of `1..34`"], value_result.error_messages
  end

  def test_cast_with_error
    value_result = (1..34).cast("-1")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "-1", value_result.value
    assert_equal ["`-1` is not within `1..34`"], value_result.error_messages
  end

  def test_cast_with_nil_error
    value_result = (0..9).cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to the beginning of `0..9`"], value_result.error_messages
  end

  def test_initialize_without_headers
    strong_csv = StrongCSV.new do
      let 0, 1..6
    end
    strong_csv.parse("5") do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal 5, row[0]
    end
  end

  def test_initialize_with_headers
    strong_csv = StrongCSV.new do
      let :id, "A".."Z"
    end
    data = <<~CSV
      id
      C
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal "C", row[:id]
    end
  end

  def test_literal_range_with_invalid_value
    strong_csv = StrongCSV.new do
      let :id, 1..100
    end
    result = strong_csv.parse(<<~CSV)
      id
      abc
    CSV
    refute result.all?(&:valid?)
    assert_equal(["abc"], result.map { |row| row[:id] })
    assert_equal([["`\"abc\"` can't be casted to the beginning of `1..100`"]], result.map { |row| row.errors[:id] })
  end

  def test_int_with_null
    strong_csv = StrongCSV.new do
      let :id, "a".."c"
    end
    result = strong_csv.parse(<<~CSV)
      id,
      b,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_equal(["b", nil], result.map { |row| row[:id] })
    assert_equal([nil, ["`nil` can't be casted to the beginning of `\"a\"..\"c\"`"]], result.map { |row| row.errors[:id] })
  end

  def test_literal_range_with_blank_value
    strong_csv = StrongCSV.new do
      let :id, "a".."c"
    end
    result = strong_csv.parse(<<~CSV)
      id,
      b,
      " "
    CSV
    refute result.all?(&:valid?)
    assert_equal(["b", " "], result.map { |row| row[:id] })
    assert_equal([nil, ["`\" \"` is not within `\"a\"..\"c\"`"]], result.map { |row| row.errors[:id] })
  end
end
