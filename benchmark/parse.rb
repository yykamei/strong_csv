# frozen_string_literal: true

require_relative "../lib/strong_csv"

ROWS = 100_000

def measure(label)
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts format("%-28s %6.3fs", label, t1 - t0)
end

rows = (1..ROWS).map { |i| "#{i},user#{i},#{i % 100}" }
csv = "id,name,score\n#{rows.join("\n")}"

strong_csv = StrongCSV.new do
  let :id, integer
  let :name, string
  let :score, integer
end
measure("no picker") { strong_csv.parse(csv) }

[1, 2, 3, 5].each do |n|
  with_pickers = StrongCSV.new do
    let :id, integer
    let :name, string
    let :score, integer
    n.times do |i|
      pick :id, as: :"ids#{i}" do |xs|
        xs.map(&:to_i)
      end
    end
  end
  measure("with #{n} picker(s)") { with_pickers.parse(csv) }
end

union = StrongCSV.new do
  let :name, string, integer
end
union_rows = (1..ROWS).map { |i| "u#{i}" }
measure("union (string, integer)") { union.parse("name\n#{union_rows.join("\n")}") }
