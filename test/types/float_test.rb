# frozen_string_literal: true

require_relative "../test_helper"

class TypesFloatTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Float.new.cast("-1")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_in_delta(-1.0, value_result.value)
  end

  def test_cast_unexpected_value
    value_result = StrongCSV::Types::Float.new.cast("++1.3")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "++1.3", value_result.value
    assert_equal ['`"++1.3"` can\'t be casted to Float'], value_result.error_messages
  end

  def test_cast_nil
    value_result = StrongCSV::Types::Float.new.cast(nil)

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Float"], value_result.error_messages
  end

  def test_without_headers
    strong_csv = StrongCSV.new do
      let 0, float
    end
    strong_csv.parse("40") do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta(40.0, row[0])
    end
  end

  def test_with_headers
    strong_csv = StrongCSV.new do
      let :id, float
    end
    data = <<~CSV
      id
      4,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta(4.0, row[:id])
    end
  end

  def test_with_negative_value
    strong_csv = StrongCSV.new do
      let :id, float
    end
    data = <<~CSV
      id
      -4
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta(-4.0, row[:id])
    end
  end

  def test_with_hex_value
    strong_csv = StrongCSV.new do
      let :id, float
    end
    result = strong_csv.parse(<<~CSV)
      id
      0x12
      123
    CSV
    assert result.all?(&:valid?)
    assert_equal([18.0, 123.0], result.map { |row| row[:id] })
  end

  def test_with_octal_value
    strong_csv = StrongCSV.new do
      let :id, float
    end
    result = strong_csv.parse(<<~CSV)
      id
      0o12
    CSV
    refute result.all?(&:valid?)
    assert_equal(["0o12"], result.map { |row| row[:id] })
    assert_equal([["`\"0o12\"` can't be casted to Float"]], result.map { |row| row.errors[:id] })
  end

  def test_with_float_value
    strong_csv = StrongCSV.new do
      let :id, float
    end
    result = strong_csv.parse(<<~CSV)
      id
      4.5
    CSV
    assert result.all?(&:valid?)
    assert_equal([4.5], result.map { |row| row[:id] })
  end

  def test_with_non_numeric_value
    strong_csv = StrongCSV.new do
      let :id, float
    end
    result = strong_csv.parse(<<~CSV)
      id
      abc
    CSV
    refute result.all?(&:valid?)
    assert_equal(["abc"], result.map { |row| row[:id] })
    assert_equal([["`\"abc\"` can't be casted to Float"]], result.map { |row| row.errors[:id] })
  end

  def test_with_null
    strong_csv = StrongCSV.new do
      let :id, float
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_equal([3, nil], result.map { |row| row[:id] })
    assert_equal([nil, ["`nil` can't be casted to Float"]], result.map { |row| row.errors[:id] })
  end

  def test_with_blank_value
    strong_csv = StrongCSV.new do
      let :id, float
    end
    result = strong_csv.parse(<<~CSV)
      id,
      3,
      " "
    CSV
    refute result.all?(&:valid?)
    assert_equal([3, " "], result.map { |row| row[:id] })
    assert_equal([nil, ["`\" \"` can't be casted to Float"]], result.map { |row| row.errors[:id] })
  end

  def test_with_pick
    db_records = [1.1, 2.2, 3.3]
    strong_csv = StrongCSV.new do
      let :id, float(constraint: ->(v) { twice.include?(v) })
      pick :id, as: :twice do |xs|
        xs = xs.map(&:to_f)
        db_records.select { |x| xs.include?(x) }
      end
    end
    result = strong_csv.parse(<<~CSV)
      id
      1.1
      3.3
      2.2
    CSV
    assert result.all?(&:valid?)
    assert_equal([1.1, 3.3, 2.2], result.map { |row| row[:id] })
  end
end
