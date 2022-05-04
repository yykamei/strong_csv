# frozen_string_literal: true

require "i18n"
I18n.load_path << File.join(__dir__, "locale.yml")

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "strong_csv"

require "minitest/autorun"
