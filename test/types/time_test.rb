# frozen_string_literal: true

require_relative "../test_helper"

class TypesTimeTest < Minitest::Test
  def test_cast
    value_result = StrongCSV::Types::Time.new.cast("2022-05-03")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 2022, value_result.value.year
    assert_equal 5, value_result.value.month
    assert_equal 3, value_result.value.day
  end

  def test_cast_with_full_format
    value_result = StrongCSV::Types::Time.new(format: "%FT%T%:z").cast("2022-05-03T12:34:28-05:00")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal(-5 * 3600, value_result.value.utc_offset)
    assert_equal 1_651_599_268, value_result.value.to_i
  end

  def test_cast_time_with_format
    value_result = StrongCSV::Types::Time.new(format: "%H:%M").cast("14:38")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 14, value_result.value.hour
    assert_equal 38, value_result.value.min
  end

  def test_cast_unexpected_value
    value_result = StrongCSV::Types::Time.new(format: "%B").cast("foo")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "foo", value_result.value
    assert_equal ["`\"foo\"` can't be casted to Time with the format `\"%B\"`"], value_result.error_messages
  end

  def test_cast_nil
    value_result = StrongCSV::Types::Time.new.cast(nil)

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_nil value_result.value
    assert_equal ["`nil` can't be casted to Time with the format `\"%Y-%m-%d\"`"], value_result.error_messages
  end

  def test_cast_with_trailing_content
    value_result = StrongCSV::Types::Time.new.cast("2022-05-16junk")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "2022-05-16junk", value_result.value
    assert_equal ["`\"2022-05-16junk\"` can't be casted to Time with the format `\"%Y-%m-%d\"`"], value_result.error_messages
  end

  def test_cast_with_trailing_space
    value_result = StrongCSV::Types::Time.new.cast("2022-05-16 ")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "2022-05-16 ", value_result.value
    assert_equal ["`\"2022-05-16 \"` can't be casted to Time with the format `\"%Y-%m-%d\"`"], value_result.error_messages
  end

  def test_cast_with_extra_time_component
    value_result = StrongCSV::Types::Time.new(format: "%H:%M").cast("14:38:00")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "14:38:00", value_result.value
    assert_equal ["`\"14:38:00\"` can't be casted to Time with the format `\"%H:%M\"`"], value_result.error_messages
  end

  def test_cast_with_non_padded_date
    value_result = StrongCSV::Types::Time.new.cast("2022-5-6")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 2022, value_result.value.year
    assert_equal 5, value_result.value.month
    assert_equal 6, value_result.value.day
  end

  def test_cast_with_unknown_zone_content
    value_result = StrongCSV::Types::Time.new(format: "%FT%T%:z").cast("2022-05-03T12:34:28junk")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "2022-05-03T12:34:28junk", value_result.value
  end

  def test_cast_with_overlong_offset
    value_result = StrongCSV::Types::Time.new(format: "%FT%T%:z").cast("2022-05-03T12:34:28-05:000")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "2022-05-03T12:34:28-05:000", value_result.value
  end

  def test_cast_with_named_zone
    with_timezone("America/Chicago") do
      value_result = StrongCSV::Types::Time.new(format: "%Y-%m-%d %Z").cast("2022-05-16 JST")

      assert_instance_of StrongCSV::ValueResult, value_result
      assert_predicate value_result, :success?
      assert_equal 32_400, value_result.value.utc_offset
      assert_equal 1_652_626_800, value_result.value.to_i
    end
  end

  def test_cast_with_year_only_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%Y %Z").cast("2022 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 1_640_962_800, value_result.value.to_i
  end

  def test_cast_with_year_month_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%Y-%m %Z").cast("2022-05 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 1_651_330_800, value_result.value.to_i
  end

  def test_cast_with_zero_offset
    value_result = StrongCSV::Types::Time.new(format: "%FT%T%:z").cast("2022-05-03T12:34:28+00:00")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_predicate value_result.value, :utc?
    assert_equal 1_651_581_268, value_result.value.to_i
  end

  def test_cast_with_hour_24_and_offset
    value_result = StrongCSV::Types::Time.new(format: "%Y-%m-%d %H:%M:%S %:z").cast("2022-05-16 24:30:00 +09:00")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 1_652_715_000, value_result.value.to_i
    assert_equal 30, value_result.value.min
  end

  def test_cast_with_epoch_and_fractional_seconds
    value_result = StrongCSV::Types::Time.new(format: "%s.%N %Z").cast("1660000000.123 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 123_000_000, value_result.value.nsec
    assert_equal 1_660_000_000, value_result.value.to_i
    assert_equal 32_400, value_result.value.utc_offset
  end

  def test_cast_with_negative_epoch_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%s.%N %Z").cast("-1.5 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal Rational(-3, 2), value_result.value.to_r
    assert_equal 32_400, value_result.value.utc_offset
  end

  def test_cast_with_negative_epoch_milliseconds_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%Q %Z").cast("-1500 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal Rational(-3, 2), value_result.value.to_r
  end

  def test_cast_with_fractional_epoch_below_one_second
    ["%s.%N", "%s.%L", "%Q.%N", "%Q.%L"].each do |format|
      ["0.5", "-0.5"].each do |epoch|
        value_result = StrongCSV::Types::Time.new(format: format).cast(epoch)

        assert_instance_of StrongCSV::ValueResult, value_result
        refute_predicate value_result, :success?, "#{epoch} with #{format} should be invalid"
      end
    end
  end

  def test_cast_with_fractional_epoch_below_one_second_and_zone
    ["0.5", "-0.5"].each do |epoch|
      value_result = StrongCSV::Types::Time.new(format: "%s.%N %Z").cast("#{epoch} JST")

      assert_instance_of StrongCSV::ValueResult, value_result
      refute_predicate value_result, :success?, "#{epoch} with a zone should be invalid"
    end
  end

  def test_cast_with_epoch_milliseconds_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%Q %Z").cast("1660000000123 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 1_660_000_000, value_result.value.to_i
    assert_equal 123_000_000, value_result.value.nsec
    assert_equal 32_400, value_result.value.utc_offset
  end

  def test_cast_with_unresolvable_zone_name
    value_result = StrongCSV::Types::Time.new(format: "%Y-%m-%d %Z").cast("2022-05-16 XYZ")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
    assert_equal "2022-05-16 XYZ", value_result.value
  end

  def test_cast_with_utc_zone_name
    value_result = StrongCSV::Types::Time.new(format: "%Y-%m-%d %Z").cast("2022-05-16 UTC")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 0, value_result.value.utc_offset
    assert_predicate value_result.value, :utc?
  end

  def test_cast_with_offset_inside_dst_gap
    with_timezone("America/Chicago") do
      value_result = StrongCSV::Types::Time.new(format: "%FT%T%Z").cast("2022-03-13T02:30:00GMT-05:00")

      assert_instance_of StrongCSV::ValueResult, value_result
      assert_predicate value_result, :success?
      assert_equal(-5 * 3600, value_result.value.utc_offset)
      assert_equal 1_647_156_600, value_result.value.to_i
    end
  end

  def test_cast_with_date_only_named_zone
    with_timezone("America/Havana") do
      value_result = StrongCSV::Types::Time.new(format: "%Y-%m-%d %Z").cast("2022-03-13 JST")

      assert_instance_of StrongCSV::ValueResult, value_result
      assert_predicate value_result, :success?
      assert_equal 1_647_097_200, value_result.value.to_i
    end
  end

  def test_cast_with_epoch_and_zone
    with_timezone("America/Chicago") do
      value_result = StrongCSV::Types::Time.new(format: "%s %Z").cast("1660000000 JST")

      assert_instance_of StrongCSV::ValueResult, value_result
      assert_predicate value_result, :success?
      assert_equal 32_400, value_result.value.utc_offset
      assert_equal 1_660_000_000, value_result.value.to_i
    end
  end

  def test_cast_with_time_only_format_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%H:%M %Z").cast("10:00 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
  end

  def test_cast_with_day_of_year_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%Y-%j %Z").cast("2022-100 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
  end

  def test_cast_with_week_date_and_zone
    value_result = StrongCSV::Types::Time.new(format: "%G-W%V-%u %Z").cast("2022-W18-2 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
  end

  def test_cast_with_invalid_offset_ranges
    ["+05:99", "+05:0000", "+24:00", "+5", "+005", "+00005", "+5:30", "+0:00"].each do |offset|
      value_result = StrongCSV::Types::Time.new(format: "%FT%T%:z").cast("2022-05-03T12:34:28#{offset}")

      assert_instance_of StrongCSV::ValueResult, value_result
      refute_predicate value_result, :success?, "#{offset} should be invalid"
    end
  end

  def test_cast_with_valid_offset_forms
    {
      "+05" => 18_000,
      "+0530" => 19_800,
      "+05:30" => 19_800,
      "+05:30:45" => 19_845,
      "GMT+05:30" => 19_800,
      "UTC-0800" => -28_800,
      "Z" => 0
    }.each do |offset, utc_offset|
      value_result = StrongCSV::Types::Time.new(format: "%FT%T%:z").cast("2022-05-03T12:34:28#{offset}")

      assert_predicate value_result, :success?, "#{offset} should be valid"
      assert_equal utc_offset, value_result.value.utc_offset, "#{offset} should have offset #{utc_offset}"
    end
  end

  def test_cast_with_numeric_zone_directive_rejects_names
    value_result = StrongCSV::Types::Time.new(format: "%Y-%m-%d %z").cast("2022-05-16 JST")

    assert_instance_of StrongCSV::ValueResult, value_result
    refute_predicate value_result, :success?
  end

  def test_cast_with_fractional_seconds_and_offset
    value_result = StrongCSV::Types::Time.new(format: "%FT%T.%N%:z").cast("2022-05-03T12:34:28.123456789-05:00")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 123_456_789, value_result.value.nsec
    assert_equal(-5 * 3600, value_result.value.utc_offset)
  end

  def test_cast_with_epoch_format
    value_result = StrongCSV::Types::Time.new(format: "%s").cast("1660000000")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 1_660_000_000, value_result.value.to_i
  end

  def test_cast_with_fractional_seconds
    value_result = StrongCSV::Types::Time.new(format: "%FT%T.%N").cast("2022-05-03T12:34:28.123456789")

    assert_instance_of StrongCSV::ValueResult, value_result
    assert_predicate value_result, :success?
    assert_equal 123_456_789, value_result.value.nsec
  end

  def test_without_headers
    strong_csv = StrongCSV.new do
      let 0, time
    end
    strong_csv.parse("2022-05-16") do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta Time.new(2022, 5, 16), row[0], 1
    end
  end

  def test_with_headers
    strong_csv = StrongCSV.new do
      let :id, time
    end
    data = <<~CSV
      id
      2022-05-16,5,6
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      assert_predicate row, :valid?
      assert_in_delta Time.new(2022, 5, 16), row[:id], 1
    end
  end

  def test_with_format
    strong_csv = StrongCSV.new do
      let :id, time(format: "%H:%M")
    end
    data = <<~CSV
      id
      123
    CSV
    strong_csv.parse(data) do |row|
      assert_instance_of StrongCSV::Row, row
      refute_predicate row, :valid?
      assert_equal("123", row[:id])
      assert_equal(["`\"123\"` can't be casted to Time with the format `\"%H:%M\"`"], row.errors[:id])
    end
  end

  def test_with_null
    strong_csv = StrongCSV.new do
      let :id, time
    end
    result = strong_csv.parse(<<~CSV)
      id,
      2022-05-16,
      ,
    CSV
    refute result.all?(&:valid?)
    assert_in_delta Time.new(2022, 5, 16), result[0][:id], 1
    assert_nil result[1][:id]
    assert_equal([nil, ["`nil` can't be casted to Time with the format `\"%Y-%m-%d\"`"]], result.map { |row| row.errors[:id] })
  end

  private

  def with_timezone(timezone)
    previous = ENV.fetch("TZ", nil)
    ENV["TZ"] = timezone
    yield
  ensure
    ENV["TZ"] = previous
  end
end
