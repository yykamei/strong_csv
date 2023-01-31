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
end
