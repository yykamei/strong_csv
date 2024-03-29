# frozen_string_literal: true

require_relative "../test_helper"

class LiteralStringTest < Minitest::Test
  using StrongCSV::Types::Literal

  def test_cast
    value_result = "abc".cast("abc")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal "abc", value_result.value
  end

  def test_cast_unexpected_value
    value_result = "x".cast("13")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "13", value_result.value
    assert_equal ["`\"x\"` is expected, but `\"13\"` was given"], value_result.error_messages
  end

  def test_cast_nil
    value_result = "😇".cast(nil)

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_nil value_result.value
    assert_equal ["`\"😇\"` is expected, but `nil` was given"], value_result.error_messages
  end

  def test_with_string_literal
    strong_csv = StrongCSV.new do
      let :id, "abc"
    end
    result = strong_csv.parse(<<~CSV)
      id,
      "abc"
      ,
      "xyz"
    CSV
    refute result.all?(&:valid?)
    assert_equal(["abc", nil, "xyz"], result.map { |row| row[:id] })
    assert_equal([nil, ["`\"abc\"` is expected, but `nil` was given"], ["`\"abc\"` is expected, but `\"xyz\"` was given"]], result.map { |row| row.errors[:id] })
  end

  def test_with_string_literal_and_union
    strong_csv = StrongCSV.new do
      let :id, "abc", "xyz"
    end
    result = strong_csv.parse(<<~CSV)
      id,
      "abc"
      "xyz"
    CSV
    assert result.all?(&:valid?)
    assert_equal(%w[abc xyz], result.map { |row| row[:id] })
  end

  def test_with_let_block
    strong_csv = StrongCSV.new do
      let :size, "S", "M", "L" do |size|
        case size
        when "S"
          1
        when "M"
          2
        when "L"
          3
        end
      end
    end
    result = strong_csv.parse(<<~CSV)
      size
      S
      M
      L
    CSV
    assert result.all?(&:valid?)
    assert_equal([1, 2, 3], result.map { |row| row[:size] })
  end
end
