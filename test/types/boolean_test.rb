# frozen_string_literal: true

require_relative "../test_helper"

class TypesBooleanTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Boolean.new.cast("True")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert value_result.value
  end

  def test_cast_unexpected_value
    value_result = StrongCSV::Types::Boolean.new.cast("1.3")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "1.3", value_result.value
    assert_equal ['`"1.3"` can\'t be casted to Boolean'], value_result.error_messages
  end

  def test_cast_nil
    value_result = StrongCSV::Types::Boolean.new.cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Boolean"], value_result.error_messages
  end

  def test_cast_with_all_possible_values
    %w[true TRUE True].each do |value|
      value_result = StrongCSV::Types::Boolean.new.cast(value)
      assert value_result.value
    end
    %w[false FALSE False].each do |value|
      value_result = StrongCSV::Types::Boolean.new.cast(value)
      refute value_result.value
    end
  end

  def test_without_headers
    strong_csv = StrongCSV.new do
      let 0, boolean
      let 1, boolean
    end
    strong_csv.parse("True,FALSE") do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert row[0]
      refute row[1]
    end
  end

  def test_with_headers
    strong_csv = StrongCSV.new do
      let :id, boolean
    end
    data = <<~CSV
      id
      false,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      refute row[:id]
    end
  end

  def test_with_non_boolean_value
    strong_csv = StrongCSV.new do
      let :id, boolean
    end
    result = strong_csv.parse(<<~CSV)
      id
      abc
    CSV
    refute result.all?(&:valid?)
    assert_equal(["abc"], result.map { |row| row[:id] })
    assert_equal([["`\"abc\"` can't be casted to Boolean"]], result.map { |row| row.errors[:id] })
  end

  def test_with_null
    strong_csv = StrongCSV.new do
      let :id, boolean
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_equal(["3", nil], result.map { |row| row[:id] })
    assert_equal([["`\"3\"` can't be casted to Boolean"], ["`nil` can't be casted to Boolean"]], result.map { |row| row.errors[:id] })
  end

  def test_with_blank_value
    strong_csv = StrongCSV.new do
      let :id, boolean
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      " "
    CSV
    refute result.all?(&:valid?)
    assert_equal(["3", " "], result.map { |row| row[:id] })
    assert_equal([["`\"3\"` can't be casted to Boolean"], ["`\" \"` can't be casted to Boolean"]], result.map { |row| row.errors[:id] })
  end
end
