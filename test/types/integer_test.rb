# frozen_string_literal: true

require_relative "../test_helper"

class TypesIntegerTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Integer.new.cast("-1")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal(-1, value_result.value)
  end

  def test_cast_unexpected_value
    value_result = StrongCSV::Types::Integer.new.cast("1.3")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "1.3", value_result.value
    assert_equal ['`"1.3"` can\'t be casted to Integer'], value_result.error_messages
  end

  def test_cast_nil
    value_result = StrongCSV::Types::Integer.new.cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Integer"], value_result.error_messages
  end

  def test_without_headers
    strong_csv = StrongCSV.new do
      let 0, integer
    end
    strong_csv.parse("40") do |row|
      assert_instance_of StrongCSV::Row, row
      assert row.valid?
      assert_equal 40, row[0]
    end
  end

  def test_with_headers
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

  def test_with_negative_value
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

  def test_with_hex_value
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

  def test_with_octal_value
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

  def test_with_float_value
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

  def test_with_non_numeric_value
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

  def test_with_null
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

  def test_with_blank_value
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

  def test_with_pick
    strong_csv = StrongCSV.new do
      let 0, integer
      let 1, integer(constraint: ->(v) { twice.include?(v) })
      pick 0, as: :twice do |xs|
        xs.map { |x| x.to_i * 2 }
      end
    end
    result = strong_csv.parse(<<~CSV)
      3,8
      4,20
      10,6
    CSV
    assert result.all?(&:valid?)
    assert_equal([3, 4, 10], result.map { |row| row[0] })
    assert_equal([8, 20, 6], result.map { |row| row[1] })
  end

  def test_with_pick_and_headers
    db_records = [1, 2, 5]
    strong_csv = StrongCSV.new do
      let :id, integer(constraint: ->(v) { ids.include?(v) })
      pick :id, as: :ids do |xs|
        xs = xs.map(&:to_i)
        db_records.select { |x| xs.include?(x) }
      end
    end
    result = strong_csv.parse(<<~CSV)
      id
      1
      2
      1
      5
      3
    CSV
    refute result.all?(&:valid?)
    assert_equal([1, 2, 1, 5, "3"], result.map { |row| row[:id] })
    assert_equal([nil, nil, nil, nil, ["`\"3\"` does not satisfy the specified constraint"]], result.map { |row| row.errors[:id] })
  end
end
