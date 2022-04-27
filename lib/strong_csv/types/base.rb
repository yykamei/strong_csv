# frozen_string_literal: true

class StrongCSV
  module Types
    # Base class for all types.
    class Base
      def cast(_value)
        raise NotImplementedError
      end
    end
  end
end
