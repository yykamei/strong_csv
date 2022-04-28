# frozen_string_literal: true

require_relative "../test_helper"

class TypesTimeTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Time.new.cast("2022-05-03T12:34:28-05:00")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal 2022, value_result.value.year
    assert_equal 5, value_result.value.month
    assert_equal 3, value_result.value.day
  end

  def test_cast_with_format
    value_result = StrongCSV::Types::Time.new(format: "%H:%M").cast("14:38")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal 14, value_result.value.hour
    assert_equal 38, value_result.value.min
  end

  def test_cast_with_error
    value_result = StrongCSV::Types::Time.new(format: "%B").cast("foo")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "foo", value_result.value
    assert_equal ["`\"foo\"` can't be casted to Time with the format `%B`"], value_result.error_messages
  end

  def test_cast_with_nil_error
    value_result = StrongCSV::Types::Time.new.cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Time"], value_result.error_messages
  end

  def test_without_headers
    strong_csv = StrongCSV.new do
      let 0, time
    end
    strong_csv.parse("2022-05-16") do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_in_delta Time.new(2022, 5, 16), row[0], 1
    end
  end

  def test_with_headers
    strong_csv = StrongCSV.new do
      let :id, time
    end
    data = <<~CSV
      id
      2022-05-16,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_in_delta Time.new(2022, 5, 16), row[:id], 1
    end
  end

  def test_with_format
    strong_csv = StrongCSV.new do
      let :id, time(format: "%H:%M")
    end
    data = <<~CSV
      id
      123
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      refute row.valid?
      assert_equal("123", row[:id])
      assert_equal(["`\"123\"` can't be casted to Time with the format `%H:%M`"], row.errors[:id])
    end
  end

  def test_with_null
    strong_csv = StrongCSV.new do
      let :id, time
    end
    result = strong_csv.parse(<<~CSV)
      id,
      2022-05-16,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_in_delta Time.new(2022, 5, 16), result[0][:id], 1
    assert_nil result[1][:id]
    assert_equal([nil, ["`nil` can't be casted to Time"]], result.map { |row| row.errors[:id] })
  end
end
