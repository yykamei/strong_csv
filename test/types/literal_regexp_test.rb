# frozen_string_literal: true

require_relative "../test_helper"

class LiteralRegexpTest < Minitest::Test
  using StrongCSV::Types::Literal

  def test_cast
    value_result = /\Aabc/.cast("abc!!!")
    assert_instance_of StrongCSV::ValueResult, value_result
    assert value_result.success?
    assert_equal "abc!!!", value_result.value
  end

  def test_cast_unexpected_value
    value_result = /\A\d+\z/.cast("1df3")
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_equal "1df3", value_result.value
    assert_equal ["`\"1df3\"` did not match `/\\A\\d+\\z/`"], value_result.error_messages
  end

  def test_cast_nil
    value_result = /abc/.cast(nil)
    assert_instance_of StrongCSV::ValueResult, value_result
    refute value_result.success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to String"], value_result.error_messages
  end

  def test_with_regexp_literal
    strong_csv = StrongCSV.new do
      let :id, /\A\w+\z/
    end
    result = strong_csv.parse(<<~CSV)
      id,
      "abc_123"
      ,
      "xyz_456!"
    CSV
    refute result.all?(&:valid?)
    assert_equal(["abc_123", nil, "xyz_456!"], result.map { |row| row[:id] })
    assert_equal([nil, ["`nil` can't be casted to String"], ["`\"xyz_456!\"` did not match `/\\A\\w+\\z/`"]], result.map { |row| row.errors[:id] })
  end

  def test_with_regexp_literal_and_union
    strong_csv = StrongCSV.new do
      let :id, /\A\d+\z/, /\A[a-z]+\z/
    end
    result = strong_csv.parse(<<~CSV)
      id,
      "abcz"
      "123"
    CSV
    assert result.all?(&:valid?)
    assert_equal(%w[abcz 123], result.map { |row| row[:id] })
  end
end
