# frozen_string_literal: true

require_relative "test_helper"

class RowTest < Minitest::Test
  def test_row_initialize_without_headers
    types = [
      StrongCSV::TypeWrapper.new(name: 0, type: StrongCSV::Types::Integer.new),
      StrongCSV::TypeWrapper.new(name: 1, type: StrongCSV::Types::Integer.new)
    ]
    row = StrongCSV::Row.new(row: %w[50 88], types: types, lineno: 3)

    assert_predicate row, :valid?
    assert_equal 50, row[0]
    assert_equal 88, row[1]
    assert_equal 3, row.lineno
  end

  def test_row_initialize_with_headers
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 91])
    types = [
      StrongCSV::TypeWrapper.new(name: :abc, type: StrongCSV::Types::Integer.new),
      StrongCSV::TypeWrapper.new(name: :xyz, type: StrongCSV::Types::Integer.new)
    ]
    row = StrongCSV::Row.new(row: csv_row, types: types, lineno: 2)

    assert_predicate row, :valid?
    assert_equal 34, row[:abc]
    assert_equal 91, row[:xyz]
    assert_equal 2, row.lineno
  end

  def test_row_forwardable
    types = [
      StrongCSV::TypeWrapper.new(name: 0, type: StrongCSV::Types::String.new),
      StrongCSV::TypeWrapper.new(name: 1, type: StrongCSV::Types::Float.new)
    ]
    row = StrongCSV::Row.new(row: %w[☕️ 12.0], types: types, lineno: 3)

    assert_equal({ 0 => "☕️", 1 => 12.0 }, row.slice(0, 1))
    assert_equal "☕️", row[0]
    assert_in_delta(12.0, row.fetch(1))
  end

  def test_row_with_invalid_data
    csv_row = CSV::Row.new(%i[abc], %w[abc!])
    types = [
      StrongCSV::TypeWrapper.new(name: :abc, type: StrongCSV::Types::Integer.new),
      StrongCSV::TypeWrapper.new(name: :x, type: StrongCSV::Types::Integer.new)
    ]
    row = StrongCSV::Row.new(row: csv_row, types: types, lineno: 2)

    refute_predicate row, :valid?
    assert_equal "abc!", row[:abc]
    assert_equal({ abc: ["`\"abc!\"` can't be casted to Integer"], x: ["`nil` can't be casted to Integer"] }, row.errors)
  end

  def test_row_with_invalid_data_with_error_message
    csv_row = CSV::Row.new(%i[abc], %w[abc!])
    types = [
      StrongCSV::TypeWrapper.new(name: :abc, type: StrongCSV::Types::Integer.new, error_message: "😡"),
      StrongCSV::TypeWrapper.new(name: :x, type: StrongCSV::Types::Float.new)
    ]
    row = StrongCSV::Row.new(row: csv_row, types: types, lineno: 2)

    refute_predicate row, :valid?
    assert_equal "abc!", row[:abc]
    assert_equal({ abc: ["😡"], x: ["`nil` can't be casted to Float"] }, row.errors)
  end

  def test_row_with_invalid_data_lacking_headers
    csv_row = CSV::Row.new(%i[abc], %w[abc!])
    types = [
      StrongCSV::TypeWrapper.new(name: :xyz, type: StrongCSV::Types::Integer.new)
    ]
    row = StrongCSV::Row.new(row: csv_row, types: types, lineno: 2)

    refute_predicate row, :valid?
    assert_raises KeyError do
      row.fetch(:abc)
    end

    assert_nil row.fetch(:xyz)
  end

  def test_row_access_values
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 91])
    types = [
      StrongCSV::TypeWrapper.new(name: :abc, type: StrongCSV::Types::Integer.new),
      StrongCSV::TypeWrapper.new(name: :xyz, type: StrongCSV::Types::Integer.new)
    ]
    row = StrongCSV::Row.new(row: csv_row, types: types, lineno: 2)

    assert_predicate row, :valid?
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
    types = [
      StrongCSV::TypeWrapper.new(name: :abc, type: StrongCSV::Types::Integer.new),
      StrongCSV::TypeWrapper.new(name: :xyz, type: StrongCSV::Types::Boolean.new, block: ->(v) { v ? "🎉" : "🤔" })
    ]
    row = StrongCSV::Row.new(row: csv_row, types: types, lineno: 2)

    assert_predicate row, :valid?
    assert_equal 34, row[:abc]
    assert_equal "🤔", row[:xyz]
  end

  def test_block_without_calling_due_to_error
    csv_row = CSV::Row.new(%i[abc xyz], %w[34 NO])
    types = [
      StrongCSV::TypeWrapper.new(name: :abc, type: StrongCSV::Types::Integer.new, block: ->(v) { v > 30 ? "🍔" : "😇" }),
      StrongCSV::TypeWrapper.new(name: :xyz, type: StrongCSV::Types::Boolean.new, block: ->(v) { v ? "🎉" : "🤔" })
    ]
    row = StrongCSV::Row.new(row: csv_row, types: types, lineno: 2)

    refute_predicate row, :valid?
    assert_equal "🍔", row[:abc]
    assert_equal "NO", row[:xyz]
  end
end
