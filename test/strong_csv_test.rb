# frozen_string_literal: true

require "test_helper"

class StrongCSVTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil StrongCSV::VERSION
  end

  def test_initialize_without_headers
    strong_csv = StrongCSV.new do
      let 0, integer
    end
    assert_instance_of StrongCSV, strong_csv
  end

  def test_initialize_with_headers
    strong_csv = StrongCSV.new do
      let :abc, integer
    end
    assert_instance_of StrongCSV, strong_csv
  end

  def test_parse
    strong_csv = StrongCSV.new do
      let :abc, integer
    end
    result = strong_csv.parse("abc\n123\n455")
    assert_instance_of Array, result
    assert(result.all? { |row| row.is_a?(StrongCSV::Row) })
    assert_equal([123, 455], result.map { |row| row[:abc] })
  end

  def test_parse_with_block
    strong_csv = StrongCSV.new do
      let :abc, integer
    end
    strong_csv.parse("abc\n123\n455") do |row|
      assert_instance_of StrongCSV::Row, row
      assert_instance_of Integer, row[:abc]
    end
  end
end
