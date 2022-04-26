# frozen_string_literal: true

require "test_helper"

class RowTest < Minitest::Test
  def test_row_initialize_without_headers
    row = StrongCSV::Row.new(row: %w[50 88], types: { 0 => StrongCSV::Types::Integer.new, 1 => StrongCSV::Types::Integer.new }, lineno: 3)
    assert row.valid?
    assert_equal 50, row[0]
    assert_equal 88, row[1]
    assert_equal 3, row.lineno
  end

  def test_row_initialize_with_headers
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 91])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: StrongCSV::Types::Integer.new, xyz: StrongCSV::Types::Integer.new }, lineno: 2)
    assert row.valid?
    assert_equal 34, row[:abc]
    assert_equal 91, row[:xyz]
    assert_equal 2, row.lineno
  end

  def test_row_with_invalid_data
    csv_row = CSV::Row.new(%i[abc], %w[abc!])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: StrongCSV::Types::Integer.new, x: StrongCSV::Types::Integer.new }, lineno: 2)
    refute row.valid?
    assert_equal "abc!", row[:abc]
    assert_equal({ abc: ["`\"abc!\"` can't be casted to Integer"], x: ["`nil` can't be casted to Integer"] }, row.errors)
  end

  def test_row_with_invalid_data_lacking_headers
    csv_row = CSV::Row.new(%i[abc], %w[abc!])
    row = StrongCSV::Row.new(row: csv_row, types: { xyz: StrongCSV::Types::Integer.new }, lineno: 2)
    refute row.valid?
    assert_raises KeyError do
      row.fetch(:abc)
    end
    assert_nil row.fetch(:xyz)
  end

  def test_row_access_values
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 91])
    row = StrongCSV::Row.new(row: csv_row, types: { abc: StrongCSV::Types::Integer.new, xyz: StrongCSV::Types::Integer.new }, lineno: 2)
    assert row.valid?
    assert_equal 34, row[:abc]
    assert_equal 34, row.fetch(:abc)
    assert_equal 91, row[:xyz]
    assert_equal 91, row.fetch(:xyz)
    assert_raises KeyError do
      row.fetch(:hey)
    end
  end
end
