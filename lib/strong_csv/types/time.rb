# frozen_string_literal: true

class StrongCSV
  module Types
    # Time type
    class Time < Base
      # Matches the numeric offset forms accepted by this type: +05, +0530,
      # +05:30, +05:30:45, and the same forms with a GMT/UTC prefix.
      OFFSET_TOKEN = /\A(?:gmt|utc)?[+-](?:[01]\d|2[0-3])(?::[0-5]\d(?::[0-5]\d)?|[0-5]\d(?:[0-5]\d)?)?\z/i.freeze
      private_constant :OFFSET_TOKEN

      # @param format [String] The format of #strptime
      def initialize(format: "%Y-%m-%d")
        raise ArgumentError, "`format` must be a String" unless format.is_a?(::String)

        super()
        @format = format
        @zone_name_allowed = format.include?("%Z")
      end

      # @param value [Object] Value to be casted to Time
      # @return [ValueResult]
      def cast(value)
        return failure(value) if value.nil?

        string = value.to_s
        # Time.strptime stops at the end of the format and ignores the rest,
        # so check the unconsumed suffix reported by Date._strptime first.
        parsed = ::Date._strptime(string, @format)
        return failure(value) unless parsed_valid?(parsed)

        time = parsed.key?(:zone) ? build_zoned_time(parsed) : ::Time.strptime(string, @format)
        return failure(value) if time.nil?

        ValueResult.new(value: time, original_value: value)
      rescue ArgumentError, RangeError
        failure(value)
      end

      private

      def failure(value)
        ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Time with the format `#{@format.inspect}`"])
      end

      def parsed_valid?(parsed)
        return false if parsed.nil? || parsed[:leftover]
        return false if ambiguous_epoch?(parsed)

        !invalid_zone?(parsed)
      end

      # Date._strptime loses the sign of a fractional epoch whose whole-second
      # part is zero, so such values cannot be casted reliably.
      def ambiguous_epoch?(parsed)
        parsed.key?(:seconds) && parsed[:seconds].zero? && parsed.fetch(:sec_fraction, 0).positive?
      end

      # Date._strptime accepts loose zone tokens and may leave :offset nil,
      # in which case Time.strptime silently uses the local timezone.
      def invalid_zone?(parsed)
        zone = parsed[:zone]
        return false if zone.nil?
        return true if parsed[:offset].nil?
        return true unless valid_zone_token?(zone)

        false
      end

      def valid_zone_token?(zone)
        return OFFSET_TOKEN.match?(zone) if zone.match?(/\d/)
        return true if zone == "Z"

        @zone_name_allowed
      end

      # Build the Time from the parsed fields so the result does not depend on
      # the host timezone or its DST rules. Zone-bearing formats other than epoch
      # directives must include a year; day-of-year and week-date directives are
      # not supported with a zone.
      def build_zoned_time(parsed)
        return nil if unsupported_date_fields?(parsed)

        offset = parsed[:offset]
        return build_zoned_epoch(parsed, offset) if parsed.key?(:seconds)
        return nil unless parsed.key?(:year)

        time = ::Time.new(parsed[:year], parsed.fetch(:mon, 1), parsed.fetch(:mday, 1), 0, 0, 0, offset) + seconds_of_day(parsed)
        utc_time(time, offset)
      end

      def build_zoned_epoch(parsed, offset)
        seconds = parsed[:seconds]
        fraction = parsed.fetch(:sec_fraction, 0)
        seconds += seconds.negative? ? -fraction : fraction
        utc_time(::Time.at(seconds).getlocal(offset), offset)
      end

      def seconds_of_day(parsed)
        (parsed.fetch(:hour, 0) * 3600) + (parsed.fetch(:min, 0) * 60) + parsed.fetch(:sec, 0) + parsed.fetch(:sec_fraction, 0)
      end

      def utc_time(time, offset)
        offset.zero? ? time.utc : time
      end

      def unsupported_date_fields?(parsed)
        parsed.key?(:yday) || parsed.key?(:cwyear) || parsed.key?(:cweek) || parsed.key?(:cwday) || parsed.key?(:wnum0) || parsed.key?(:wnum1)
      end
    end
  end
end
