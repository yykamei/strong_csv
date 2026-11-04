# frozen_string_literal: true

class StrongCSV
  module Types
    # Literal is a module to collect all the literal types for CSV parsing.
    # This module is intended for refining built-in classes and provide `#cast` like `Base` class.
    module Literal
      # The default time limit, in seconds, for matching a Regexp literal on Ruby 3.2 and later.
      REGEXP_TIMEOUT = 1.0
      private_constant :REGEXP_TIMEOUT

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
        # @param value [Object]
        # @return [Integer, nil, :timeout] The match position, nil, or :timeout when the match exceeded the limit
        def regexp_match(regexp, value)
          matcher = regexp_with_timeout(regexp)

          if defined?(::Regexp::TimeoutError)
            begin
              matcher =~ value
            rescue ::Regexp::TimeoutError
              :timeout
            end
          else
            matcher =~ value
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
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{int.inspect}` was given"])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Integer"])
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
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{float.inspect}` was given"])
          end
        rescue ArgumentError, TypeError
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to Float"])
        end
      end

      refine ::Range do
        # @param value [Object] Value to be casted to Range
        # @return [ValueResult]
        def cast(value)
          return ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to the beginning of `#{inspect}`"]) if value.nil?

          casted = case self.begin
                   when ::Float
                     Float(value)
                   when ::Integer
                     Integer(value)
                   when ::String
                     value
                   else
                     raise TypeError, "#{self.begin.class} is not supported"
                   end
          if cover?(casted)
            ValueResult.new(value: casted, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{casted.inspect}` is not within `#{inspect}`"])
          end
        rescue ArgumentError
          ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to the beginning of `#{inspect}`"])
        end
      end

      refine ::String do
        # @param value [Object] Value to be casted to String
        # @return [ValueResult]
        def cast(value)
          if self == value
            ValueResult.new(value: self, original_value: value)
          else
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` is expected, but `#{value.inspect}` was given"])
          end
        end
      end

      refine ::Regexp do
        # @param value [Object] Value to be casted to String
        # @return [ValueResult]
        def cast(value)
          return ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` can't be casted to String"]) if value.nil?

          case Literal.regexp_match(self, value)
          when :timeout
            ValueResult.new(original_value: value, error_messages: ["`#{inspect}` matching timed out"])
          when nil
            ValueResult.new(original_value: value, error_messages: ["`#{value.inspect}` did not match `#{inspect}`"])
          else
            ValueResult.new(value: value, original_value: value)
          end
        end
      end
    end
  end
end
