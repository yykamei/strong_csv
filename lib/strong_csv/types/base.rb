# frozen_string_literal: true

class StrongCSV
  module Types
    # Base class for all types.
    class Base
      def cast(_value)
        raise NotImplementedError
      end

      def |(other)
        Union.new(self, other)
      end
    end
  end
end
