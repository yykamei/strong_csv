# frozen_string_literal: true

require "test_helper"

class LetTest < Minitest::Test
  def test_initialize
    let = StrongCSV::Let.new
    let.let(:abc, 123)
    let.let(:xyz, 243)
    assert_equal({ abc: 123, xyz: 243 }, let.types)
    assert let.headers
  end

  def test_initialize_string
    let = StrongCSV::Let.new
    let.let("abc", 123)
    let.let("xyz", 243)
    assert_equal({ abc: 123, xyz: 243 }, let.types)
    assert let.headers
  end

  def test_initialize_without_headers
    let = StrongCSV::Let.new
    let.let(0, 123)
    let.let(1, 89)
    assert_equal({ 0 => 123, 1 => 89 }, let.types)
    refute let.headers
  end

  def test_initialize_raises_with_non_compatible_keys
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

  def test_union_via_let
    let = StrongCSV::Let.new
    let.let(:id, 10..50, StrongCSV::Types::Boolean.new)
    assert_instance_of StrongCSV::Types::Union, let.types[:id]
    assert let.headers
  end

  def test_integer
    assert_instance_of StrongCSV::Types::Integer, StrongCSV::Let.new.integer
  end

  def test_boolean
    assert_instance_of StrongCSV::Types::Boolean, StrongCSV::Let.new.boolean
  end

  def test_float
    assert_instance_of StrongCSV::Types::Float, StrongCSV::Let.new.float
  end

  def test_string
    assert_instance_of StrongCSV::Types::String, StrongCSV::Let.new.string
    assert_instance_of StrongCSV::Types::String, StrongCSV::Let.new.string(within: 1..10)
  end
end
