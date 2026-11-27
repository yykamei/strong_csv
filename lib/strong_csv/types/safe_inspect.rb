# frozen_string_literal: true

class StrongCSV
  module Types
    # Builds bounded, log-safe representations of untrusted values for error messages.
    #
    # Use it whenever a cell value is interpolated into an error message.
    #
    # ```ruby
    # SafeInspect.render("\u202Eevil") # => "\"\\u202Eevil\""
    # ```
    module SafeInspect
      MAX_LENGTH = 256
      INVISIBLE_PATTERN = /[\p{Cc}\p{Cf}\p{Zl}\p{Zp}\u034F\u115F\u1160\u17B4\u17B5\u180B-\u180E\u3164\u{13430}-\u{1343F}\uFE00-\uFE0F\uFFA0\u{E0100}-\u{E01EF}]/.freeze
      private_constant :INVISIBLE_PATTERN

      class << self
        # @param value [Object]
        # @return [String] A bounded, escaped representation of the value.
        def render(value)
          text, truncated = inspect_value(value)
          text = "#{text}..." if truncated
          text.gsub(INVISIBLE_PATTERN) { |char| escape(char) }
        end

        private

        def inspect_value(value)
          if value.is_a?(::String)
            [normalize(value[0, MAX_LENGTH].inspect), value.length > MAX_LENGTH]
          else
            normalized = normalize(value.inspect)
            [normalized[0, MAX_LENGTH], normalized.length > MAX_LENGTH]
          end
        end

        def normalize(string)
          string.encode(::Encoding::UTF_8, invalid: :replace, undef: :replace)
        end

        def escape(char)
          codepoint = char.ord
          codepoint > 0xFFFF ? format("\\u{%X}", codepoint) : format("\\u%04X", codepoint)
        end
      end
    end
  end
end
