# frozen_string_literal: true

class StrongCSV
  # Let is a class that is used to define types for columns.
  class Let
    # @return [Hash{Symbol => [Types::Base, Proc]}]
    attr_reader :types

    # @return [Boolean]
    attr_reader :headers

    # @return [Hash]
    attr_reader :pickers

    def initialize
      @types = []
      @headers = false
      @pickers = {}
      @picker_columns = {}
      @picked_key = :"strong_csv_picked_#{object_id}"
    end

    # @param name [String, Symbol, Integer]
    # @param type [StrongCSV::Types::Base]
    # @param types [Array<StrongCSV::Types::Base>]
    def let(name, type, *types, error_message: nil, &block)
      type = Types::Union.new(type, *types) unless types.empty?
      case name
      when ::Integer
        @types << TypeWrapper.new(name: name, type: type, block: block, error_message: error_message)
      when ::String, ::Symbol
        @types << TypeWrapper.new(name: name.to_sym, type: type, block: block, error_message: error_message)
      else
        raise TypeError, "Invalid type specified for `name`. `name` must be String, Symbol, or Integer: #{name.inspect}"
      end
      validate_columns
    end

    # #pick is intended for defining a singleton method with `:as`.
    # This might be useful for the case where you want to receive IDs that are stored in a database,
    # and you want to make sure the IDs actually exist.
    #
    # The block receives all values of the column at once, so they are buffered in memory
    # for the entire CSV.
    #
    # @example
    #  pick :user_id, as: :user_ids do |user_ids|
    #    User.where(id: user_ids).ids
    #  end
    #
    # @param column [Symbol, Integer]
    # @param as [Symbol]
    # @yieldparam values [Array<String>] The values for the column. NOTE: This is an array of String, not casted values.
    def pick(column, as:, &block)
      raise TypeError, "`column` must be Symbol or Integer: #{column.inspect}" unless column.is_a?(::Symbol) || column.is_a?(::Integer)
      raise TypeError, "`as` must be a Symbol: #{as.inspect}" unless as.is_a?(::Symbol)
      raise ArgumentError, "`as` conflicts with an existing method: #{as.inspect}" if respond_to?(as, true)

      define_singleton_method(as) do
        picked[as]
      end
      @pickers[as] = block
      @picker_columns[as] = column
    end

    # It collects the values for each picker in a single pass over the CSV,
    # then invokes the picker blocks with the collected values.
    # The collected values are held in memory until the picker blocks return.
    # The CSV stream is rewound before returning so the caller can continue
    # reading from the beginning.
    #
    # @return [Hash{Symbol => Object}] The picked values by picker name.
    def pick_all(csv)
      picked_values = {}
      return picked_values if @pickers.empty?

      buffers = Hash.new { |hash, key| hash[key] = [] }
      header_checked = false
      csv.each do |row|
        unless header_checked
          validate_headers(csv.headers)
          header_checked = true
        end
        @pickers.each_key { |as| buffers[as] << row[@picker_columns[as]] }
      end
      # Report a schema mismatch before the seekability requirement.
      validate_headers(csv.headers) unless header_checked
      rewind!(csv)
      with_picked(picked_values) do
        @pickers.each { |as, block| picked_values[as] = block.call(buffers[as]) }
      end
      picked_values
    end

    # Runs the block with the picked values for the current parse.
    #
    # The constraint and block closures created by the DSL call picker methods
    # on this instance, so the per-parse values must be reachable without
    # changing those closures. Fiber-local storage keeps concurrent threads and
    # fibers isolated and is restored when the block returns. Picker methods
    # raise outside this scope instead of silently returning nil.
    #
    # @param picked [Hash{Symbol => Object}]
    # @return [Object] The block's return value.
    def with_picked(picked)
      previous = Thread.current[@picked_key]
      Thread.current[@picked_key] = picked
      yield
    ensure
      Thread.current[@picked_key] = previous
    end

    # Finalizes the header mode after all declarations are known.
    #
    # Index-based `let` declarations cannot be combined with a Symbol picker
    # column because the picker would index a row by Symbol.
    #
    # @raise [ArgumentError] when Symbol pick columns are combined with
    #   index-based `let` declarations.
    def validate_declarations
      if @types.empty?
        @headers = @picker_columns.values.any?(::Symbol)
        return
      end

      return if @headers
      return unless @picker_columns.values.any?(::Symbol)

      raise ArgumentError, "Symbol pick columns require header-based `let` declarations"
    end

    # Verifies that every declared symbol column appears exactly once in the
    # CSV header. Extra columns are ignored, and index-based declarations are
    # not checked.
    #
    # @param headers [Array<Symbol>, true, false, nil]
    # @raise [HeaderError] when a declared column is missing or duplicated.
    def validate_headers(headers)
      return unless @headers

      errors = header_errors(headers)
      raise HeaderError, "invalid CSV headers (#{errors.join(", ")})" unless errors.empty?
    end

    # @param options [Hash] See `Types::Integer#initialize` for more details.
    def integer(**options)
      Types::Integer.new(**options)
    end

    # @param options [Hash] See `Types::Integer#initialize` for more details.
    def integer?(**options)
      optional(integer(**options))
    end

    def boolean
      Types::Boolean.new
    end

    def boolean?
      optional(boolean)
    end

    # @param options [Hash] See `Types::Float#initialize` for more details.
    def float(**options)
      Types::Float.new(**options)
    end

    # @param options [Hash] See `Types::Float#initialize` for more details.
    def float?(**options)
      optional(float(**options))
    end

    # @param options [Hash] See `Types::String#initialize` for more details.
    def string(**options)
      Types::String.new(**options)
    end

    # @param options [Hash] See `Types::String#initialize` for more details.
    def string?(**options)
      optional(string(**options))
    end

    # @param options [Hash] See `Types::Time#initialize` for more details.
    def time(**options)
      Types::Time.new(**options)
    end

    # @param options [Hash] See `Types::Time#initialize` for more details.
    def time?(**options)
      optional(time(**options))
    end

    # @param args [Array] See `Types::Optional#initialize` for more details.
    def optional(*args)
      Types::Optional.new(*args)
    end

    private

    def picked
      context = Thread.current[@picked_key]
      raise Error, "picked values are only available during parse" if context.nil?

      context
    end

    def rewind!(csv)
      csv.rewind
    rescue IOError, NoMethodError, SystemCallError => e
      raise NotSeekableError, "pick requires a seekable input; buffer the CSV before parsing", cause: e
    end

    def header_errors(headers)
      required = required_columns
      return ["missing: #{required.inspect}"] unless headers.is_a?(::Array)

      missing = required - headers
      duplicated = required.select { |name| headers.count(name) > 1 }
      error_messages(missing, duplicated)
    end

    def required_columns
      (@types.map(&:name) + @picker_columns.values.grep(::Symbol)).uniq
    end

    def error_messages(missing, duplicated)
      messages = []
      messages << "missing: #{missing.inspect}" unless missing.empty?
      messages << "duplicated: #{duplicated.inspect}" unless duplicated.empty?
      messages
    end

    def validate_columns
      if @types.all? { |t| t.name.is_a?(Integer) }
        @headers = false
      elsif @types.all? { |k| k.name.is_a?(Symbol) }
        @headers = true
      else
        raise ArgumentError, "`types` cannot be mixed with Integer and Symbol keys: #{@types.map(&:name).inspect}"
      end
    end
  end
end
