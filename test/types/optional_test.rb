# frozen_string_literal: true

require_relative "../test_helper"

class TypesOptionalTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Optional.new(StrongCSV::Types::Integer.new).cast("-1")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal(-1, value_result.value)
  end

  def test_cast_unexpected_value
    value_result = StrongCSV::Types::Optional.new(StrongCSV::Types::Integer.new).cast("1.3")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "1.3", value_result.value
    assert_equal ['`"1.3"` can\'t be casted to Integer'], value_result.error_messages
  end

  def test_cast_nil
    value_result = StrongCSV::Types::Optional.new(StrongCSV::Types::Integer.new).cast(nil)

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_nil value_result.value
  end

  def test_without_headers
    strong_csv = StrongCSV.new do
      let 0, optional(integer)
    end
    strong_csv.parse("40") do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_equal 40, row[0]
    end
  end

  def test_with_headers
    strong_csv = StrongCSV.new do
      let :id, integer?
    end
    data = <<~CSV
      id
      4,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_equal 4, row[:id]
    end
  end

  def test_strong_csv_for_with_optional_integer
    strong_csv = StrongCSV.new do
      let 0, optional(integer)
    end
    result = strong_csv.parse("\n\n\n123\n")

    assert result.all?(&:valid?)
    assert_equal([nil, nil, nil, 123], result.map { |row| row[0] })
  end

  def test_strong_csv_for_with_optional_string
    strong_csv = StrongCSV.new do
      let 0, string?(within: 1..10)
    end
    result = strong_csv.parse("\n\nabc\n\n")

    assert result.all?(&:valid?)
    assert_equal([nil, nil, "abc", nil], result.map { |row| row[0] })
  end

  def test_strong_csv_for_with_optional_float
    strong_csv = StrongCSV.new do
      let 0, float?
    end
    result = strong_csv.parse("\n\n1.2\n\n")

    assert result.all?(&:valid?)
    assert_equal([nil, nil, 1.2, nil], result.map { |row| row[0] })
  end

  def test_strong_csv_for_with_optional_boolean
    strong_csv = StrongCSV.new do
      let 0, boolean?
    end
    result = strong_csv.parse("True\n\nfalse\n\n")

    assert result.all?(&:valid?)
    assert_equal([true, nil, false, nil], result.map { |row| row[0] })
  end

  def test_strong_csv_for_with_optional_time
    strong_csv = StrongCSV.new do
      let 0, time?
    end
    result = strong_csv.parse("2022-06-09\n\n2015-05-03\n\n")

    assert result.all?(&:valid?)
    assert_equal([Time.new(2022, 6, 9), nil, Time.new(2015, 5, 3), nil], result.map { |row| row[0] })
  end

  def test_strong_csv_for_with_optional_literal
    strong_csv = StrongCSV.new do
      let 0, optional("yy")
    end
    result = strong_csv.parse("\n\nyy\n\n")

    assert result.all?(&:valid?)
    assert_equal([nil, nil, "yy", nil], result.map { |row| row[0] })
  end

  def test_strong_csv_for_with_optional_union_literal
    strong_csv = StrongCSV.new do
      let 0, optional("yy"), optional("xx")
    end
    result = strong_csv.parse("\nxx\nyy\n\n")

    assert result.all?(&:valid?)
    assert_equal([nil, "xx", "yy", nil], result.map { |row| row[0] })
  end
end
