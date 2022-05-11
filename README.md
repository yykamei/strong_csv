# strong_csv

<a href="https://rubygems.org/gems/strong_csv"><img alt="strong_csv" src="https://img.shields.io/gem/v/strong_csv"></a>

NOTE: This repository is still under development 🚧🚜🚧

Type checker for a CSV file inspired by [strong_json](https://github.com/soutaro/strong_json).

## Motivation

Some applications have a feature to receive a CSV file uploaded by a user,
and in general, it needs to validate each cell of the CSV file.

How should applications validate them?
Of course, it depends, but there would be common validation logic for CSV files.
For example, some columns may have to be integers because of database requirements.
It would be cumbersome to write such validations always.

strong_json helps you to mitigate such a drudgery by letting you declare desired types beforehand.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "strong_csv"
```

And then execute:

```console
bundle
```

Or install it yourself as:

```console
gem install strong_csv
```

## Usage

The most important APIs of strong_csv are `StrongCSV.new` and `StrongCSV#parse`.
`StrongCSV.new` lets you declare types for each CSV column with Ruby's block syntax.
Inside the block, you will mainly use `let` and declare types for a column.

After defining types, you can parse CSV content with `StrongCSV#parse`.
`StrongCSV#parse` won't raise errors as possible and just store error messages in its rows.
The reason why it won't raise errors is CSV content may contain _invalid_ rows,
but sometimes, it makes sense to ignore them and process something for _valid_ rows.
If you want to stop all processes with invalid rows,
check whether all rows are valid before proceeding with computation.

Here is an example usage of this gem:

```ruby
require "strong_csv"

strong_csv = StrongCSV.new do
  let :stock, integer
  let :tax_rate, float
  let :name, string(within: 1..255)
  let :description, string?(within: 1..1000)
  let :active, boolean
  let :started_at, time?(format: "%Y-%m-%dT%H:%M:%S")

  # Literal declaration
  let :status, 0..6
  let :priority, 10, 20, 30, 40, 50
  let :size, "S", "M", "L" do |value|
    case value
    when "S"
      1
    when "M"
      2
    when "L"
      3
    end
  end

  # Regular expressions
  let :url, %r{\Ahttps://}

  # Custom validation
  #
  # This example sees the database to fetch exactly stored `User` IDs,
  # and it checks the `:user_id` cell really exists in the `users` table.
  # `pick` would be useful to avoid N+1 problems.
  pick :user_id, as: :user_ids do |ids|
    User.where(id: ids).ids
  end
  let :user_id, integer(constraint: ->(i) { user_ids.include?(i) })
end

data = <<~CSV
  stock,tax_rate,name,active,status,priority,size,url
  12,0.8,special item,True,4,20,M,https://example.com
CSV

strong_csv.parse(data, field_size_limit: 2048) do |row|
  if row.valid?
    row[:tax_rate] # => 0.8
    row[:active] # => true
    # do something with row
  else
    row.errors # => { user_id: ["`nil` can't be casted to Integer"] }
    # do something with row.errors
  end
end
```

You can also define types without CSV headers by specifying column numbers.
Note the numbers must start from `0` (zero-based index).

```ruby
StrongCSV.new do
  let 0, integer
  let 1, string
  let 2, 1..10
end
```

This declaration expects a CSV has the contents like this:

```csv
123,abc,3
830,mno,10
```

## Available types

<table>
    <tr>
        <th>Type</th>
        <th>Description</th>
    </tr>
    <tr>
        <td><a href="#integer-and-integer"><code>integer</code> and <code>integer?</code></a></td>
        <td>The value must be casted to <code>Integer</code>.</td>
    </tr>
    <tr>
        <td><a href="#float-and-float"><code>float</code> and <code>float?</code></a></td>
        <td>The value must be casted to <code>Float</code>.</td>
    </tr>
    <tr>
        <td><a href="#boolean-and-boolean"><code>boolean</code> and <code>boolean?</code></a></td>
        <td>The value must be casted to Boolean (<code>true</code> or <code>false</code>).</td>
    </tr>
    <tr>
        <td><a href="#string-and-string"><code>string</code> and <code>string?</code></a></td>
        <td>The value must be casted to <code>String</code>.</td>
    </tr>
    <tr>
        <td><a href="#time-and-time"><code>time</code> and <code>time?</code></a></td>
        <td>The value must be casted to <code>Time</code>.</td>
    </tr>
    <tr>
        <td><a href="#optional"><code>optional</code></a></td>
        <td>The value can be <code>nil</code>. If the value exists, it must satisfy the given type constraint.</td>
    </tr>
    <tr>
        <td><a href="#literal"><code>23</code> (Integer literal)</a></td>
        <td>The value must be casted to the specific <code>Integer</code> literal.</td>
    </tr>
    <tr>
        <td><a href="#literal"><code>15.12</code> (Float literal)</a></td>
        <td>The value must be casted to the specific <code>Float</code> literal.</td>
    </tr>
    <tr>
        <td><a href="#literal"><code>1..10</code> (Range literal)</a></td>
        <td>The value must be casted to the beginning of <code>Range</code> and be covered with it.</td>
    </tr>
    <tr>
        <td><a href="#literal"><code>"abc"</code> (String literal)</a></td>
        <td>The value must be casted to the specific <code>String</code> literal.</td>
    </tr>
    <tr>
        <td><a href="#literal"><code>%r{\Ahttps://}</code> (Regexp literal)</a></td>
        <td>The value must be casted to a <code>String</code> that matches the specified Regexp.</td>
    </tr>
    <tr>
        <td><a href="#union"><code>,</code> (Union type)</a></td>
        <td>The value must satisfy one of the subtypes.</td>
    </tr>
</table>

### `integer` and `integer?`

The value must be casted to Integer. `integer?` allows the value to be `nil`, so you can declare optional integer type
for columns. It also lets you allow values that satisfy the specified limitation through `:constraint`.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let :stock, integer
  let :state, integer?
  let :user_id, integer(constraint: ->(v) { user_ids.include?(v)})
  pick :user_id, as: :user_ids do |values|
    User.where(id: values).ids
  end
end

result = strong_csv.parse(<<~CSV)
  stock,state,user_id
  12,0,1
  20,,2
  non-integer,1,4
CSV

result.map(&:valid?) # => [true, true, false]
result[0].slice(:stock, :state, :user_id) # => {:stock=>12, :state=>0, :user_id=>1}
result[1].slice(:stock, :state, :user_id) # => {:stock=>20, :state=>nil, :user_id=>2}
result[2].slice(:stock, :state, :user_id) # => {:stock=>"non-integer", :state=>1, :user_id=>"4"}
result[2].errors.slice(:stock, :user_id) # => {:stock=>["`\"non-integer\"` can't be casted to Integer"], :user_id=>["`\"4\"` does not satisfy the specified constraint"]}
```

### `float` and `float?`

The value must be casted to Float. `float?` allows the value to be `nil`, so you can declare optional float type for
columns. It also lets you allow values that satisfy the specified limitation through `:constraint`.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let :tax_rate, float
  let :fail_rate, float?
end

result = strong_csv.parse(<<~CSV)
  tax_rate,fail_rate
  0.02,0.1
  0.05,
  ,0.8
CSV

result.map(&:valid?) # => [true, true, false]
result[0].slice(:tax_rate, :fail_rate) # => {:tax_rate=>0.02, :fail_rate=>0.1}
result[1].slice(:tax_rate, :fail_rate) # => {:tax_rate=>0.05, :fail_rate=>nil}
result[2].slice(:tax_rate, :fail_rate) # => {:tax_rate=>nil, :fail_rate=>0.8} (`nil` is not allowed for `tax_rate`)
```

### `boolean` and `boolean?`

The value must be casted to Boolean (`true` of `false`).
`"true"`, `"True"`, and `"TRUE"` are casted to `true`,
while `"false"`, `"False"`, and `"FALSE"` are casted to `false`.
`boolean?` allows the value to be `nil` as an optional boolean
value.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let :enabled, boolean
  let :active, boolean?
end

result = strong_csv.parse(<<~CSV)
  enabled,active
  True,True
  False,
  ,
CSV

result.map(&:valid?) # => [true, true, false]
result[0].slice(:enabled, :active) # => {:enabled=>true, :active=>true}
result[1].slice(:enabled, :active) # => {:enabled=>false, :active=>nil}
result[2].slice(:enabled, :active) # => {:enabled=>nil, :active=>nil} (`nil` is not allowed for `enabled`)
```

### `string` and `string?`

The value must be casted to String. `string?` allows the value to be `nil` as an optional string value.
They also support `:within` in its arguments, and it limits the length of the string value within the specified `Range`.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let :name, string(within: 1..4)
  let :description, string?
end

result = strong_csv.parse(<<~CSV)
  name,description
  JB,Hello
  yykamei,
  ,🤷
CSV

result.map(&:valid?) # => [true, false, false]
result[0].slice(:name, :description) # => {:name=>"JB", :description=>"Hello"}
result[1].slice(:name, :description) # => {:name=>"yykamei", :description=>nil} ("yykamei" exceeds the `Range` specified with `:within`)
result[2].slice(:name, :description) # => {:name=>nil, :description=>"🤷"} (`nil` is not allowed for `name`)
```

### `time` and `time?`

The value must be casted to Time. `time?` allows the value to be `nil` as an optional time value.
They have the `:format` argument, which is used as the format
of [`Time.strptime`](https://rubydoc.info/stdlib/time/Time.strptime);
it means you can ensure the value must satisfy the time format. The default value of `:format` is `"%Y-%m-%d"`.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let :start_on, time
  let :updated_at, time?(format: "%FT%T")
end

result = strong_csv.parse(<<~CSV)
  start_on,updated_at
  2022-04-01,2022-04-30T15:30:59
  2022-05-03
  05-03,2021-09-03T09:48:23
CSV

result.map(&:valid?) # => [true, true, false]
result[0].slice(:start_on, :updated_at) # => {:start_on=>2022-04-01 00:00:00 +0900, :updated_at=>2022-04-30 15:30:59 +0900}
result[1].slice(:start_on, :updated_at) # => {:start_on=>2022-05-03 00:00:00 +0900, :updated_at=>nil}
result[2].slice(:start_on, :updated_at) # => {:start_on=>"05-03", :updated_at=>2021-09-03 09:48:23 +0900} ("05-03" does not satisfy the default format `"%Y-%m-%d"`)
```

### `optional`

While each type above has its optional type with `?`, literals cannot be suffixed with `?`.
However, there would be a case to have an optional literal type.
In this case, `optional` might be useful and lets you declare such types.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let :foo, optional(123)
  let :bar, optional("test")
end

result = strong_csv.parse(<<~CSV)
  foo,bar
  123,test
  ,
  124
CSV

result.map(&:valid?) # => [true, true, false]
result[0].slice(:foo, :bar) # => {:foo=>123, :bar=>"test"}
result[1].slice(:foo, :bar) # => {:foo=>nil, :bar=>nil}
result[2].slice(:foo, :bar) # => {:foo=>"124", :bar=>nil} (124 is not equal to 123)
```

### Literal

You can declare literal value as types. The supported literals are `Integer`, `Float`, `String`, and `Range`.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let 0, 123
  let 1, "test"
  let 2, 2.5
  let 3, 1..10
  let 4, /[a-z]+/
end

result = strong_csv.parse(<<~CSV)
  123,test,2.5,9,abc
  123,test,2.5,0,xyz
  123,Hey,2.5,10,!
CSV

result.map(&:valid?) # => [true, false, false]
result[0].slice(0, 1, 2, 3, 4) # => {0=>123, 1=>"test", 2=>2.5, 3=>9, 4=>"abc"}
result[1].slice(0, 1, 2, 3, 4) # => {0=>123, 1=>"test", 2=>2.5, 3=>"0", 4=>"xyz"} (0 is out of 1..10)
result[2].slice(0, 1, 2, 3, 4) # => {0=>123, 1=>"Hey", 2=>2.5, 3=>10, 4=>"!"} ("Hey" is not equal to "test", and "!" does not match /[a-z]+/)
```

### Union

There would be a case that it's alright if a value satisfies one of the types.
Union types are useful for such a case.

_Example_

```ruby
strong_csv = StrongCSV.new do
  let :priority, 10, 20, 30
  let :size, "S", "M", "L"
end

result = strong_csv.parse(<<~CSV)
  priority,size
  10,M
  30,A
  11,S
CSV

result.map(&:valid?) # => [true, false, false]
result[0].slice(:priority, :size) # => {:priority=>10, :size=>"M"}
result[1].slice(:priority, :size) # => {:priority=>30, :size=>"A"} ("A" is not one of "S", "M", and "L")
result[2].slice(:priority, :size) # => {:priority=>"11", :size=>"S"} (11 is not one of 10, 20, and 30)
```

## I18n (Internationalization)

strong_csv depends on [i18n](https://rubygems.org/gems/i18n) for internationalization.
If you want to have a locale-specific error message, put the message catalog in your locale files.
Here is an example of a locale file.

```yaml
ja:
  strong_csv:
    boolean:
      cant_be_casted: "`%{value}`はBooleanに変換できません"
    float:
      cant_be_casted: "`%{value}`はFloatに変換できません"
      constraint_error: "`%{value}`は指定された成約を満たしていません",
    integer:
      cant_be_casted: "`%{value}`はIntegerに変換できません"
      constraint_error: "`%{value}`は指定された成約を満たしていません",
    literal:
      integer:
        unexpected: "`%{expected}`ではなく`%{value}`が入力されています"
        cant_be_casted: "`%{expected}`ではなく`%{value}`が入力されています"
      float:
        unexpected: "`%{expected}`ではなく`%{value}`が入力されています"
        cant_be_casted: "`%{value}`はFloatに変換できません"
      string:
        unexpected: "`%{expected}`ではなく`%{value}`が入力されています"
      range:
        cant_be_casted: "`%{value}`は`%{expected}`の始端に変換できません"
        out_of_range: "`%{value}`は`%{range}`の範囲外です"
      regexp:
        cant_be_casted: "`%{value}`はStringに変換できません"
        unexpected: "`%{value}`は`%{expected}`とマッチしませんでした"
    string:
      cant_be_casted: "`%{value}`はStringに変換できません"
      out_of_range: "`%{value}`の文字数は`%{range}`の範囲外です"
    time:
      cant_be_casted: "`%{value}`は`%{time_format}`でTimeに変換できません"
```

## Contributing

Bug reports and pull requests are welcome on the [GitHub repository](https://github.com/yykamei/strong_csv).
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the
[code of conduct](https://github.com/yykamei/strong_csv/blob/main/CODE_OF_CONDUCT.md).
