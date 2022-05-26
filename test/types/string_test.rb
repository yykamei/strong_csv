# frozen_string_literal: true

require_relative "../test_helper"

class TypesStringTest < Minitest::Test
  def test_initialize_raise_error
    skip "We cannot test this case with rbs/test/setup enabled"
    assert_raises ArgumentError do
      StrongCSV::Types::String.new(within: 123)
    end
  end

  def test_cast
    value_result = StrongCSV::Types::String.new.cast("-1")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal("-1", value_result.value)
  end

  def test_cast_out_of_range
    value_result = StrongCSV::Types::String.new(within: 1..4).cast("foo_box")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "foo_box", value_result.value
    assert_equal ["The length of `\"foo_box\"` is out of range `1..4`"], value_result.error_messages
  end

  def test_cast_nil
    value_result = StrongCSV::Types::String.new.cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to String"], value_result.error_messages
  end

  def test_without_headers
    strong_csv = StrongCSV.new do
      let 0, string
    end
    strong_csv.parse("40") do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal "40", row[0]
    end
  end

  def test_with_headers
    strong_csv = StrongCSV.new do
      let :id, string
    end
    data = <<~CSV
      id
      4,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal "4", row[:id]
    end
  end

  def test_with_negative_value
    strong_csv = StrongCSV.new do
      let :id, string
    end
    data = <<~CSV
      id
      -4
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal("-4", row[:id])
    end
  end

  def test_with_size
    strong_csv = StrongCSV.new do
      let :id, string(within: 1..3)
    end
    data = <<~CSV
      id
      abcd
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      refute row.valid?
      assert_equal("abcd", row[:id])
      assert_equal(["The length of `\"abcd\"` is out of range `1..3`"], row.errors[:id])
    end
  end

  def test_with_hex_value
    strong_csv = StrongCSV.new do
      let :id, string
    end
    result = strong_csv.parse(<<~CSV)
      id
      0x12
      123
    CSV
    assert result.all?(&:valid?)
    assert_equal(%w[0x12 123], result.map { |row| row[:id] })
  end

  def test_with_string_value
    strong_csv = StrongCSV.new do
      let :id, string
    end
    result = strong_csv.parse(<<~CSV)
      id
      4.5
    CSV
    assert result.all?(&:valid?)
    assert_equal(["4.5"], result.map { |row| row[:id] })
  end

  def test_with_non_numeric_value
    strong_csv = StrongCSV.new do
      let :id, string
    end
    result = strong_csv.parse(<<~CSV)
      id
      abc
    CSV
    assert result.all?(&:valid?)
    assert_equal(["abc"], result.map { |row| row[:id] })
  end

  def test_with_null
    strong_csv = StrongCSV.new do
      let :id, string
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_equal(["3", nil], result.map { |row| row[:id] })
    assert_equal([nil, ["`nil` can't be casted to String"]], result.map { |row| row.errors[:id] })
  end

  def test_with_blank_value
    strong_csv = StrongCSV.new do
      let :id, string
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      " "
    CSV
    assert result.all?(&:valid?)
    assert_equal(["3", " "], result.map { |row| row[:id] })
  end
end
