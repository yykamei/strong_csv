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

  def test_parse_raises_on_non_seekable_pick_input
    called = false
    strong_csv = StrongCSV.new do
      pick :id, as: :ids do |values|
        called = true
        values
      end
      let :id, integer
    end

    reader, writer = IO.pipe
    writer.write("id\n1\n")
    writer.close

    error = assert_raises(StrongCSV::NotSeekableError) do
      strong_csv.parse(reader)
    end
    assert_kind_of SystemCallError, error.cause
    refute called
  ensure
    reader.close
    writer.close unless writer.closed?
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

  def test_parse_raises_on_missing_declared_header
    strong_csv = StrongCSV.new do
      let :id, integer
      let :name, string?
    end

    error = assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id\n1\n")
    end

    assert_includes error.message, ":name"
  end

  def test_parse_raises_on_duplicate_declared_header
    strong_csv = StrongCSV.new do
      let :id, integer
    end

    error = assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id,id\n1,2\n")
    end

    assert_includes error.message, ":id"
  end

  def test_parse_allows_extra_headers
    strong_csv = StrongCSV.new do
      let :id, integer
    end
    result = strong_csv.parse("id,extra\n1,x\n")

    assert_predicate result.first, :valid?
    assert_equal 1, result.first[:id]
  end

  def test_parse_does_not_validate_headers_for_index_declarations
    strong_csv = StrongCSV.new do
      let 0, integer
    end
    result = strong_csv.parse("1\n2\n")

    assert_equal([1, 2], result.map { |row| row[0] })
  end

  def test_parse_raises_on_missing_picked_header
    strong_csv = StrongCSV.new do
      let :id, integer
      pick :name, as: :names do |values|
        values
      end
    end

    assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id\n1\n")
    end
  end

  def test_parse_checks_headers_before_picker_blocks_run
    called = false
    strong_csv = StrongCSV.new do
      let :id, integer
      pick :name, as: :names do |values|
        called = true
        values
      end
    end

    assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id\n1\n")
    end
    refute called
  end

  def test_parse_raises_on_missing_declared_header_without_data_rows
    strong_csv = StrongCSV.new do
      let :id, integer
      let :name, string?
    end

    assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id\n")
    end
  end

  def test_parse_raises_on_duplicate_declared_header_without_data_rows
    strong_csv = StrongCSV.new do
      let :id, integer
    end

    assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id,id\n")
    end
  end

  def test_parse_raises_on_empty_input
    strong_csv = StrongCSV.new do
      let :id, integer
    end

    assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("")
    end
  end

  def test_parse_accepts_valid_header_only_input
    strong_csv = StrongCSV.new do
      let :id, integer
    end

    assert_equal([], strong_csv.parse("id\n"))
  end

  def test_parse_does_not_run_pickers_on_header_only_input
    called = false
    strong_csv = StrongCSV.new do
      let :id, integer
      pick :name, as: :names do |values|
        called = true
        values
      end
    end

    assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id\n")
    end
    refute called
  end

  def test_header_error_reports_missing_and_duplicated_headers
    strong_csv = StrongCSV.new do
      let :id, integer
      let :name, string?
    end

    error = assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("id,id\n1,2\n")
    end

    assert_includes error.message, ":id"
    assert_includes error.message, ":name"
  end

  def test_header_error_does_not_include_untrusted_header_values
    strong_csv = StrongCSV.new do
      let :id, integer
    end

    error = assert_raises(StrongCSV::HeaderError) do
      strong_csv.parse("attacker_supplied\n1\n")
    end

    refute_includes error.message, "attacker_supplied"
  end

  def test_initialize_rejects_symbol_pick_with_index_declarations
    assert_raises ArgumentError do
      StrongCSV.new do
        let 0, integer
        pick :name, as: :names do |values|
          values
        end
      end
    end
  end

  def test_pick_only_with_symbol_column_treats_first_row_as_headers
    picked = nil
    strong_csv = StrongCSV.new do
      pick :id, as: :ids do |values|
        picked = values
        values
      end
    end
    strong_csv.parse("id\n1\n2\n")

    assert_equal %w[1 2], picked
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
