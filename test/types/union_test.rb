# frozen_string_literal: true

require_relative "../test_helper"

class TypesUnionTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Union.new(12, 3).cast("3")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal 3, value_result.value
  end

  def test_cast_with_multiple_types
    value_result = StrongCSV::Types::Union.new(12, 4, StrongCSV::Types::Float.new).cast("3")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal 3.0, value_result.value
  end

  def test_cast_with_error
    value_result = StrongCSV::Types::Union.new(10, 8, 9.34, "abc").cast("1.3")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "1.3", value_result.value
    assert_equal ["`\"1.3\"` can't be casted to Integer", "`9.34` is expected, but `1.3` was given", "`\"abc\"` is expected, but `\"1.3\"` was given"], value_result.error_messages
  end

  def test_cast_with_nil_error
    value_result = StrongCSV::Types::Union.new(10, 11).cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Integer"], value_result.error_messages
  end

  def test_cast_with_error_of_multiple_types
    value_result = StrongCSV::Types::Union.new(10, StrongCSV::Types::Boolean.new).cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Integer", "`nil` can't be casted to Boolean"], value_result.error_messages
  end

  def test_with_multiple_values
    strong_csv = StrongCSV.new do
      let 0, integer, boolean
    end
    result = strong_csv.parse(<<~CSV)
      123
      20
      False
      0
      TRUE
    CSV
    assert result.all?(&:valid?)
    assert_equal([123, 20, false, 0, true], result.map { |row| row[0] })
  end

  def test_with_multiple_values_including_error
    strong_csv = StrongCSV.new do
      let :id, integer, boolean
    end
    result = strong_csv.parse(<<~CSV)
      id
      😇
      123
      20
      False
      0
      TRUE
      1.3
    CSV
    assert_equal [false, true, true, true, true, true, false], result.map(&:valid?)
    assert_equal(["😇", 123, 20, false, 0, true, "1.3"], result.map { |row| row[:id] })
    assert_equal(
      [
        ["`\"😇\"` can't be casted to Integer", "`\"😇\"` can't be casted to Boolean"],
        nil,
        nil,
        nil,
        nil,
        nil,
        ["`\"1.3\"` can't be casted to Integer", "`\"1.3\"` can't be casted to Boolean"]
      ],
      result.map { |row| row.errors[:id] }
    )
  end

  def test_with_many_multiple_values
    strong_csv = StrongCSV.new do
      let 0, 10, 20, 30, 40, 50
    end
    result = strong_csv.parse(<<~CSV)
      15
    CSV
    refute result.all?(&:valid?)
    assert_equal(["15"], result.map { |row| row[0] })
    assert_equal(
      [
        [
          "`10` is expected, but `15` was given",
          "`20` is expected, but `15` was given",
          "`30` is expected, but `15` was given",
          "`40` is expected, but `15` was given",
          "`50` is expected, but `15` was given"
        ]
      ],
      result.map { |row| row.errors[0] }
    )
  end
end
