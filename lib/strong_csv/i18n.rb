# frozen_string_literal: true

I18n.backend.store_translations(
  :en, {
    _strong_csv: {
      boolean: {
        cant_be_casted: "`%{value}` can't be casted to Boolean",
      },
      float: {
        cant_be_casted: "`%{value}` can't be casted to Float",
      },
      integer: {
        cant_be_casted: "`%{value}` can't be casted to Integer",
        constraint_error: "`%{value}` does not satisfy the specified constraint",
      },
      literal: {
        integer: {
          unexpected: "`%{expected}` is expected, but `%{value}` was given",
          cant_be_casted: "`%{value}` can't be casted to Integer",
        },
        float: {
          unexpected: "`%{expected}` is expected, but `%{value}` was given",
          cant_be_casted: "`%{value}` can't be casted to Float",
        },
        string: {
          unexpected: "`%{expected}` is expected, but `%{value}` was given",
        },
        range: {
          cant_be_casted: "`%{value}` can't be casted to the beginning of `%{expected}`",
          out_of_range: "`%{value}` is not within `%{range}`",
        },
        regexp: {
          cant_be_casted: "`%{value}` can't be casted to String",
          unexpected: "`%{value}` did not match `%{expected}`",
        },
      },
      string: {
        cant_be_casted: "`%{value}` can't be casted to String",
        out_of_range: "The length of `%{value}` is out of range `%{range}`",
      },
      time: {
        cant_be_casted: "`%{value}` can't be casted to Time with the format `%{time_format}`",
      },
    },
  },
)
