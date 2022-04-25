# frozen_string_literal: true

require "test_helper"

class TestStrongCSV < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil StrongCSV::VERSION
  end

  def test_initialize_without_headers
    strong_csv = StrongCSV.new do
      let 0, 123
    end
    assert_instance_of StrongCSV, strong_csv
  end
end
