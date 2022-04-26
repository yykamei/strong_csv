# strong_csv

NOTE: This repository is still under development 🚧🚜🚧

Type checker for a CSV file inspired by [strong_json](https://github.com/soutaro/strong_json).

**Motivation**

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
gem 'strong_csv'
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

TBD: This hasn't yet been implemented.

```ruby
strong_csv = StrongCSV.new do
  let :stock, integer
  let :tax_rate, float
  let :name, string(255)
  let :description, string?(1000)
  let :active, boolean
  let :started_at, time?
  let :data, any?

  # Literal declaration
  let :status, 0..6
  let :priority, 10 | 20 | 30 | 40 | 50
  let :size, "S" | "M" | "L" do |value|
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

  # Custom validation.
  #
  # This example sees the database to fetch exactly stored `User` IDs,
  # and it checks the `:user_id` cell really exists in the `users` table.
  # `pick` would be useful to avoid N+1 problems.
  pick :user_id, as: :user_ids do |ids|
    User.where(id: ids).ids
  end
  let :user_id, integer { |i| user_ids.include?(i) }
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
    row.errors # => { user_id: ["must be present", "must be an integer"] }
    # do something with row.errors
  end
end
```

## Available types

| Type                        | Description                                  | Example               |
| --------------------------- | -------------------------------------------- | --------------------- |
| integer                     | The value must be casted to Integer          | `let :stock, integer` |
| 1, 2, ... (Integer literal) | The value must be casted to specific Integer | `let :id, 3`          |

## Contributing

Bug reports and pull requests are welcome on the [GitHub repository](https://github.com/yykamei/strong_csv).
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the
[code of conduct](https://github.com/yykamei/strong_csv/blob/main/CODE_OF_CONDUCT.md).
