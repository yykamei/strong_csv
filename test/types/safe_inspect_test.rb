# frozen_string_literal: true

require_relative "../test_helper"

class SafeInspectTest < Minitest::Test
  def test_render_keeps_short_values
    assert_equal "\"abc\"", StrongCSV::Types::SafeInspect.render("abc")
  end

  def test_render_bounds_long_values
    rendered = StrongCSV::Types::SafeInspect.render("x" * 300)

    assert_operator rendered.length, :<, 300
    assert_match(/\A".{256}"\.\.\.\z/, rendered)
  end

  def test_render_escapes_gb18030_hieroglyph_format_controls
    value = "\u{13430}".encode(Encoding::GB18030)

    rendered = StrongCSV::Types::SafeInspect.render(value)

    refute_includes rendered, "\u{13430}"
    assert_match(/\\u\{13430\}|\\x\{/, rendered)
  end

  def test_render_escapes_bidi_and_zero_width_characters
    rendered = StrongCSV::Types::SafeInspect.render("\u202Eevil\u200B")

    assert_includes rendered, "\\u202E"
    assert_includes rendered, "\\u200B"
    refute_includes rendered, "\u202E"
    refute_includes rendered, "\u200B"
  end

  def test_render_handles_non_strings
    assert_equal "nil", StrongCSV::Types::SafeInspect.render(nil)
    assert_equal "42", StrongCSV::Types::SafeInspect.render(42)
  end

  def test_render_handles_invalid_encoding
    rendered = StrongCSV::Types::SafeInspect.render("x\xFF")

    assert_includes rendered, "\\xFF"
  end

  def test_render_escapes_default_ignorable_characters
    rendered = StrongCSV::Types::SafeInspect.render("a\u0085b\u206Ac\u{E0041}d\u{E0100}e")

    assert_includes rendered, "\\u0085"
    assert_includes rendered, "\\u206A"
    assert_includes rendered, "\\u{E0041}"
    assert_includes rendered, "\\u{E0100}"
    refute_includes rendered, "\u0085"
    refute_includes rendered, "\u206A"
    refute_includes rendered, "\u{E0041}"
    refute_includes rendered, "\u{E0100}"
  end

  def test_render_handles_non_utf8_default_encoding
    previous_external = Encoding.default_external
    previous_internal = Encoding.default_internal
    Encoding.default_external = Encoding::Windows_31J
    Encoding.default_internal = nil
    value = "１".encode(Encoding::Windows_31J)

    rendered = StrongCSV::Types::SafeInspect.render(value)

    assert_includes rendered, "１"
  ensure
    Encoding.default_external = previous_external
    Encoding.default_internal = previous_internal
  end

  def test_render_handles_long_utf16_values
    value = ("あ" * 300).encode(Encoding::UTF_16LE)

    rendered = StrongCSV::Types::SafeInspect.render(value)

    assert_includes rendered, "..."
    assert_operator rendered.length, :<, 2_000
  end
end
