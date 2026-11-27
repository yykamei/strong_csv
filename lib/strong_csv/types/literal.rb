# frozen_string_literal: true

class StrongCSV
  module Types
    # Literal is a module to collect all the literal types for CSV parsing.
    # This module is intended for refining built-in classes and provide `#cast` like `Base` class.
    module Literal # rubocop:disable Metrics/ModuleLength
      # The default time limit, in seconds, for matching a Regexp literal on Ruby 3.2 and later.
      REGEXP_TIMEOUT = 1.0

      # Internal error for a range begin type that cannot be casted.
      class UnsupportedBeginType < TypeError; end

      private_constant :REGEXP_TIMEOUT, :UnsupportedBeginType

      class << self
        # Returns a Regexp that enforces the default match timeout.
        #
        # The original Regexp is returned when the running Ruby has no regexp
        # timeout support, or when a per-Regexp or global timeout is already set.
        #
        # @param regexp [Regexp]
        # @return [Regexp]
        def regexp_with_timeout(regexp)
          return regexp unless defined?(::Regexp::TimeoutError)
          return regexp if regexp.timeout || ::Regexp.timeout

          ::Regexp.new(regexp.source, regexp.options, timeout: REGEXP_TIMEOUT)
        end

        # Matches the value against the Regexp with the default timeout.
        #
        # @param regexp [Regexp]
        # @param value [String]
        # @return [Integer, nil, :timeout, :incompatible_encoding] The match
        #   position, nil, :timeout when the match exceeded the limit, or
        #   :incompatible_encoding when the value cannot be matched.
        def regexp_match(regexp, value)
          matcher = regexp_with_timeout(regexp)

          if defined?(::Regexp::TimeoutError)
            begin
              matcher =~ value
            rescue ::Regexp::TimeoutError
              :timeout
            rescue ::Encoding::CompatibilityError, ::ArgumentError
              :incompatible_encoding
            end
          else
            begin
              matcher =~ value
            rescue ::Encoding::CompatibilityError, ::ArgumentError
              :incompatible_encoding
            end
          end
        end
      end

      refine ::Integer do
        # @param value [Object] Value to be casted to Integer
        # @return [ValueResult]
        def cast(value)
          int = Integer(value)
          if int == self
            ValueResult.new(value: int, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{SafeInspect.render(int)}` was given"])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: ["`#{SafeInspect.render(value)}` can't be casted to Integer"])
        end
      end

      refine ::Float do
        # @param value [Object] Value to be casted to Float
        # @return [ValueResult]
        def cast(value)
          float = Float(value)
          if float == self
            ValueResult.new(value: float, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{SafeInspect.render(float)}` was given"])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: ["`#{SafeInspect.render(value)}` can't be casted to Float"])
        end
      end

      refine ::Range do
        # @param value [Object] Value to be casted to Range
        # @return [ValueResult]
        def cast(value)
          return failure(value) if value.nil?

          begin
            casted = case self.begin
                     when ::Float then Float(value)
                     when ::Integer then Integer(value)
                     when ::String then value
                     else raise UnsupportedBeginType, "#{self.begin.class} is not supported"
                     end
            within = cover?(casted)
          rescue UnsupportedBeginType
            raise
          rescue ArgumentError, Encoding::CompatibilityError, RangeError, TypeError
            return failure(value)
          end

          if within
            ValueResult.new(value: casted, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{SafeInspect.render(casted)}` is not within `#{inspect}`"])
          end
        end

        private

        def failure(value)
          ValueResult.new(original_value: value, error_messages: ["`#{SafeInspect.render(value)}` can't be casted to the beginning of `#{inspect}`"])
        end
      end

      refine ::String do
        # @param value [Object] Value to be casted to String
        # @return [ValueResult]
        def cast(value)
          if self == value
            ValueResult.new(value: self, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{SafeInspect.render(value)}` was given"])
          end
        end
      end

      refine ::Regexp do
        # @param value [Object] Value to be casted to String
        # @return [ValueResult]
        def cast(value)
          return ValueResult.new(original_value: value, error_messages: ["`#{SafeInspect.render(value)}` can't be casted to String"]) unless value.is_a?(::String)

          case Literal.regexp_match(self, value)
          when :timeout
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` matching timed out"])
          when :incompatible_encoding
            ValueResult.new(original_value: value, error_messages: ["`#{SafeInspect.render(value)}` can't be matched against `#{inspect}` because of incompatible encodings"])
          when nil
            ValueResult.new(original_value: value, error_messages: ["`#{SafeInspect.render(value)}` did not match `#{inspect}`"])
          else
            ValueResult.new(value: value, original_value: value)
          end
        end
      end
    end
  end
end
