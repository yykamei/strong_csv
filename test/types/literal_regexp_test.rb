# frozen_string_literal: true

require_relative "../test_helper"

class LiteralRegexpTest < Minitest::Test
  using StrongCSV::Types::Literal

  def test_cast
    value_result = /\Aabc/.cast("abc!!!")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal "abc!!!", value_result.value
  end

  def test_cast_unexpected_value
    value_result = /\A\d+\z/.cast("1df3")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "1df3", value_result.value
    assert_equal ["`\"1df3\"` did not match `/\\A\\d+\\z/`"], value_result.error_messages
  end

  def test_cast_nil
    value_result = /abc/.cast(nil)

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
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

  def test_regexp_with_timeout
    skip "Regexp timeout is not supported on this Ruby" unless defined?(::Regexp::TimeoutError)

    regexp = /\Aabc\z/i
    matcher = StrongCSV::Types::Literal.regexp_with_timeout(regexp)

    refute_same regexp, matcher
    assert_in_delta(1.0, matcher.timeout)
    assert_equal regexp.options, matcher.options
  end

  def test_regexp_with_timeout_respects_existing_timeout
    skip "Regexp timeout is not supported on this Ruby" unless defined?(::Regexp::TimeoutError)

    regexp = ::Regexp.new("\\Aabc\\z", timeout: 0.5)
    matcher = StrongCSV::Types::Literal.regexp_with_timeout(regexp)

    assert_same regexp, matcher
  end

  def test_regexp_with_timeout_respects_global_timeout
    skip "Regexp timeout is not supported on this Ruby" unless defined?(::Regexp::TimeoutError)

    previous = ::Regexp.timeout
    begin
      ::Regexp.timeout = 5.0
      regexp = /\Aabc\z/

      assert_same regexp, StrongCSV::Types::Literal.regexp_with_timeout(regexp)
    ensure
      ::Regexp.timeout = previous
    end
  end

  def test_cast_with_timeout
    skip "Regexp timeout is not supported on this Ruby" unless defined?(::Regexp::TimeoutError)

    regexp = ::Regexp.new("\\A(?=(a+)+$)", timeout: 0.001)
    value = "a" * 40
    value << "!"
    value_result = regexp.cast(value)

    refute_predicate value_result, :success?
    assert_equal value, value_result.value
    assert_includes value_result.error_messages.first, "matching timed out"
  end

  def test_cast_with_default_timeout
    skip "Regexp timeout is not supported on this Ruby" unless defined?(::Regexp::TimeoutError)

    value = "a" * 40
    value << "!"
    value_result = /\A(?=(a+)+$)/.cast(value)

    refute_predicate value_result, :success?
    assert_equal value, value_result.value
    assert_includes value_result.error_messages.first, "matching timed out"
  end

  def test_cast_with_ignorecase_option
    value_result = /abc/i.cast("ABC")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal "ABC", value_result.value
  end

  def test_cast_with_multibyte_regexp
    skip "Regexp timeout is not supported on this Ruby" unless defined?(::Regexp::TimeoutError)

    value_result = /\Aあ+\z/.cast("ああ")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal "ああ", value_result.value
  end
end
