# frozen_string_literal: true

require "test_helper"

class RowTest < Minitest::Test
  def test_row_initialize_without_headers
    row = StrongCSV::Row.new(row: %w[50 88], types: { 0 => [StrongCSV::Types::Integer.new, nil], 1 => [StrongCSV::Types::Integer.new, nil] }, lineno: 3)
    assert row.valid?
    assert_equal 50, row[0]
    assert_equal 88, row[1]
    assert_equal 3, row.lineno
  end

  def test_row_initialize_with_headers
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 91])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: [StrongCSV::Types::Integer.new, nil], xyz: [StrongCSV::Types::Integer.new, nil] }, lineno: 2)
    assert row.valid?
    assert_equal 34, row[:abc]
    assert_equal 91, row[:xyz]
    assert_equal 2, row.lineno
  end

  def test_row_forwardable
    row = StrongCSV::Row.new(row: %w[☕️ 12.0], types: { 0 => [StrongCSV::Types::String.new, nil], 1 => [StrongCSV::Types::Float.new, nil] }, lineno: 3)
    assert_equal({ 0 => "☕️", 1 => 12.0 }, row.slice(0, 1))
    assert_equal "☕️", row[0]
    assert_equal 12.0, row.fetch(1)
  end

  def test_row_with_invalid_data
    csv_row = CSV::Row.new(%i[abc], %w[abc!])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: [StrongCSV::Types::Integer.new, nil], x: [StrongCSV::Types::Integer.new, nil] }, lineno: 2)
    refute row.valid?
    assert_equal "abc!", row[:abc]
    assert_equal({ abc: ["`\"abc!\"` can't be casted to Integer"], x: ["`nil` can't be casted to Integer"] }, row.errors)
  end

  def test_row_with_invalid_data_lacking_headers
    csv_row = CSV::Row.new(%i[abc], %w[abc!])
    row = StrongCSV::Row.new(row: csv_row, types: { xyz: [StrongCSV::Types::Integer.new, nil] }, lineno: 2)
    refute row.valid?
    assert_raises KeyError do
      row.fetch(:abc)
    end
    assert_nil row.fetch(:xyz)
  end

  def test_row_access_values
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 91])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: [StrongCSV::Types::Integer.new, nil], xyz: [StrongCSV::Types::Integer.new, nil] }, lineno: 2)
    assert row.valid?
    assert_equal 34, row[:abc]
    assert_equal 34, row.fetch(:abc)
    assert_equal 91, row[:xyz]
    assert_equal 91, row.fetch(:xyz)
    assert_raises KeyError do
      row.fetch(:hey)
    end
  end

  def test_block
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 false])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: [StrongCSV::Types::Integer.new, nil], xyz: [StrongCSV::Types::Boolean.new, ->(v) { v ? "🎉" : "🤔" }] }, lineno: 2)
    assert row.valid?
    assert_equal 34, row[:abc]
    assert_equal "🤔", row[:xyz]
  end

  def test_block_without_calling_due_to_error
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 NO])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: [StrongCSV::Types::Integer.new, ->(v) { v > 30 ? "🍔" : "😇" }], xyz: [StrongCSV::Types::Boolean.new, ->(v) { v ? "🎉" : "🤔" }] }, lineno: 2)
    refute row.valid?
    assert_equal "🍔", row[:abc]
    assert_equal "NO", row[:xyz]
  end
end
