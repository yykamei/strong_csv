# frozen_string_literal: true

require "timeout"

require_relative "test_helper"

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
    assert(result.all?(StrongCSV::Row))
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

  def test_parse_isolates_picked_values_between_threads
    strong_csv, a_ready = build_concurrent_picker

    rows = {}
    thread_a = Thread.new { rows[:a] = strong_csv.parse("scope,user_id\nA,2\n").first }
    thread_b = nil
    Timeout.timeout(5) do
      a_ready.pop
      thread_b = Thread.new { rows[:b] = strong_csv.parse("scope,user_id\nB,2\n").first }
      [thread_a, thread_b].each(&:join)
    end

    refute_predicate rows[:a], :valid?
    assert_predicate rows[:b], :valid?
  end

  def test_parse_isolates_picked_values_between_fibers
    strong_csv = build_fiber_picker
    rows = {}

    fiber_a = Fiber.new { rows[:a] = strong_csv.parse("scope,user_id\nA,2\n").first }
    fiber_a.resume
    fiber_b = Fiber.new { rows[:b] = strong_csv.parse("scope,user_id\nB,2\n").first }
    fiber_b.resume
    fiber_a.resume

    refute_predicate rows[:a], :valid?
    assert_predicate rows[:b], :valid?
  end

  private

  def build_fiber_picker
    StrongCSV.new do
      let :scope, string do |value|
        Fiber.yield if value == "A"
        value
      end
      pick :scope, as: :allowed_ids do |values|
        values.map { |value| value == "A" ? 1 : 2 }
      end
      let :user_id, integer(constraint: ->(id) { allowed_ids.include?(id) })
    end
  end

  def build_concurrent_picker
    a_ready = Queue.new
    b_may_finish = Queue.new

    strong_csv = StrongCSV.new do
      let :scope, string do |value|
        if value == "A"
          a_ready << true
          b_may_finish.pop
        else
          b_may_finish << true
        end
        value
      end
      pick :scope, as: :allowed_ids do |values|
        values.map { |value| value == "A" ? 1 : 2 }
      end
      let :user_id, integer(constraint: ->(id) { allowed_ids.include?(id) })
    end

    [strong_csv, a_ready]
  end
end
