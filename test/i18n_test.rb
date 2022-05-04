# frozen_string_literal: true

require "i18n"

require_relative "test_helper"

class I18nTest < Minitest::Test
  def test_precedes_user_defined_locales
    strong_csv = StrongCSV.new do
      let 0, boolean
    end
    I18n.with_locale(:ja) do
      strong_csv.parse("NO") do |row|
        assert_instance_of StrongCSV::Row, row
        refute row.valid?
        assert_equal ["失敗"], row.errors[0]
      end
    end
  end
end
