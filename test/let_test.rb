# frozen_string_literal: true

require_relative "test_helper"

class LetTest < Minitest::Test
  def test_initialize
    let = StrongCSV::Let.new
    let.let(:abc, 123)
    let.let(:xyz, 243)

    assert_equal [StrongCSV::TypeWrapper.new(name: :abc, type: 123), StrongCSV::TypeWrapper.new(name: :xyz, type: 243)], let.types
    assert let.headers
  end

  def test_initialize_string
    let = StrongCSV::Let.new
    let.let("abc", 123)
    let.let("xyz", 243)

    assert_equal [StrongCSV::TypeWrapper.new(name: :abc, type: 123), StrongCSV::TypeWrapper.new(name: :xyz, type: 243)], let.types
    assert let.headers
  end

  def test_initialize_without_headers
    let = StrongCSV::Let.new
    let.let(0, 123)
    let.let(1, 89)

    assert_equal [StrongCSV::TypeWrapper.new(name: 0, type: 123), StrongCSV::TypeWrapper.new(name: 1, type: 89)], let.types
    refute let.headers
  end

  def test_initialize_raises_with_non_compatible_keys
    skip "We cannot test this case with rbs/test/setup enabled"
    assert_raises TypeError do
      StrongCSV::Let.new.let(nil, 123)
    end
  end

  def test_initialize_raises_with_mix_of_integer_and_string_keys
    let = StrongCSV::Let.new
    let.let(0, 123)
    assert_raises ArgumentError do
      let.let(:abc, 8)
    end
  end

  def test_let_block
    let = StrongCSV::Let.new
    let.let(:id, "abc") { |v| v }

    assert_equal "abc", let.types[0].type
    assert_instance_of Proc, let.types[0].block
    assert let.headers
  end

  def test_union_via_let
    let = StrongCSV::Let.new
    let.let(:id, 10..50, StrongCSV::Types::Boolean.new) { |v| v }

    assert_instance_of StrongCSV::Types::Union, let.types[0].type
    assert_instance_of Proc, let.types[0].block
    assert let.headers
  end

  def test_error_message_via_let
    let = StrongCSV::Let.new
    let.let(0, "book", error_message: "My custom error message")

    assert_equal "My custom error message", let.types[0].error_message
  end

  def test_integer
    assert_instance_of StrongCSV::Types::Integer, StrongCSV::Let.new.integer
    assert_instance_of StrongCSV::Types::Integer, StrongCSV::Let.new.integer(constraint: ->(_v) { true })
  end

  def test_integer?
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.integer?
    assert_instance_of StrongCSV::Types::Integer, StrongCSV::Let.new.integer?.instance_variable_get(:@type)
    assert_instance_of StrongCSV::Types::Integer, StrongCSV::Let.new.integer?(constraint: ->(_v) { true }).instance_variable_get(:@type)
  end

  def test_boolean
    assert_instance_of StrongCSV::Types::Boolean, StrongCSV::Let.new.boolean
  end

  def test_boolean?
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.boolean?
    assert_instance_of StrongCSV::Types::Boolean, StrongCSV::Let.new.boolean?.instance_variable_get(:@type)
  end

  def test_float
    assert_instance_of StrongCSV::Types::Float, StrongCSV::Let.new.float
    assert_instance_of StrongCSV::Types::Float, StrongCSV::Let.new.float(constraint: ->(_v) { true })
  end

  def test_float?
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.float?
    assert_instance_of StrongCSV::Types::Float, StrongCSV::Let.new.float?.instance_variable_get(:@type)
    assert_instance_of StrongCSV::Types::Float, StrongCSV::Let.new.float?(constraint: ->(_v) { true }).instance_variable_get(:@type)
  end

  def test_string
    assert_instance_of StrongCSV::Types::String, StrongCSV::Let.new.string
    assert_instance_of StrongCSV::Types::String, StrongCSV::Let.new.string(within: 1..10)
  end

  def test_string?
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.string?
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.string?(within: 1..10)
    assert_instance_of StrongCSV::Types::String, StrongCSV::Let.new.string?.instance_variable_get(:@type)
  end

  def test_time
    assert_instance_of StrongCSV::Types::Time, StrongCSV::Let.new.time
    assert_instance_of StrongCSV::Types::Time, StrongCSV::Let.new.time(format: "%H:%M")
  end

  def test_time?
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.time?
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.time?(format: "%H:%M")
    assert_instance_of StrongCSV::Types::Time, StrongCSV::Let.new.time?.instance_variable_get(:@type)
  end

  def test_optional
    assert_instance_of StrongCSV::Types::Optional, StrongCSV::Let.new.optional(123)
  end

  def test_pick_all
    let = StrongCSV::Let.new
    let.pick(:id, as: :ids) { |xs| xs.map(&:to_i) }
    let.pick(:name, as: :names) { |xs| xs }

    csv = CSV.new("id,name\n1,foo\n2,bar\n", headers: true, header_converters: :symbol)
    let.pick_all(csv)

    assert_equal [1, 2], let.ids
    assert_equal %w[foo bar], let.names
  end

  def test_pick_all_without_headers
    let = StrongCSV::Let.new
    let.pick(0, as: :first) { |xs| xs.map(&:to_i) }

    csv = CSV.new("1\n2\n", headers: false)
    let.pick_all(csv)

    assert_equal [1, 2], let.first
  end

  def test_pick_all_with_empty_csv
    let = StrongCSV::Let.new
    let.pick(:id, as: :ids) { |xs| xs }

    csv = CSV.new("id\n", headers: true, header_converters: :symbol)
    let.pick_all(csv)

    assert_equal [], let.ids
  end

  def test_pick_all_without_pickers
    let = StrongCSV::Let.new

    csv = CSV.new("id\n1\n", headers: true, header_converters: :symbol)
    let.pick_all(csv)
  end

  def test_pick_all_leaves_csv_at_the_beginning
    let = StrongCSV::Let.new
    let.pick(:id, as: :ids) { |xs| xs.map(&:to_i) }

    csv = CSV.new("id\n1\n2\n", headers: true, header_converters: :symbol)
    let.pick_all(csv)
    first = let.ids
    let.pick_all(csv)

    assert_equal [1, 2], first
    assert_equal first, let.ids
  end

  def test_pick_all_block_can_read_earlier_picker_result
    let = StrongCSV::Let.new
    let.pick(:id, as: :ids) { |xs| xs.map(&:to_i) }
    let.pick(:id, as: :twice) { |_xs| let.ids.map { |x| x * 2 } }

    csv = CSV.new("id\n1\n2\n3\n", headers: true, header_converters: :symbol)
    let.pick_all(csv)

    assert_equal [1, 2, 3], let.ids
    assert_equal [2, 4, 6], let.twice
  end
end
