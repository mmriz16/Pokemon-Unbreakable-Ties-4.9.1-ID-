require "csv"
require "pathname"

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
TRACKING = ROOT.join("tracking")
DRAFT_CSV = TRACKING.join("story_translation_draft.csv")
ORDER_CSV = TRACKING.join("story_order_priority.md")
OUTPUT_CSV = TRACKING.join("opening_sequence_translation.csv")
SUMMARY_MD = TRACKING.join("opening_sequence_translation_summary.md")

OPENING_MAP_IDS = [22, 42, 32, 76, 78, 79, 80, 83, 88, 90, 92].freeze

rows = CSV.read(DRAFT_CSV, headers: true)
opening_rows = rows.select do |row|
  OPENING_MAP_IDS.include?(row["source_id"].to_i)
end

CSV.open(OUTPUT_CSV, "w", write_headers: true, headers: rows.headers) do |csv|
  opening_rows.each { |row| csv << row }
end

translatable = opening_rows.select { |row| row["draft_status"] == "machine_draft" }
coverage = if translatable.empty?
  0
else
  translated = translatable.count { |row| !row["draft_id"].to_s.strip.empty? }
  ((translated.to_f / translatable.length) * 100).round(2)
end

counts = opening_rows.group_by { |row| row["source_id"].to_i }.transform_values do |entries|
  {
    total: entries.length,
    translated: entries.count { |row| row["draft_status"] == "machine_draft" }
  }
end

SUMMARY_MD.write(<<~MD)
  # Opening Sequence Translation Summary

  - Output: `tracking/opening_sequence_translation.csv`
  - Opening sequence maps: #{OPENING_MAP_IDS.length}
  - Total opening sequence rows: #{opening_rows.length}
  - Translatable opening sequence rows: #{translatable.length}
  - Translation coverage: #{coverage}%

  ## Per Map
  #{OPENING_MAP_IDS.map { |map_id|
      data = counts[map_id] || { total: 0, translated: 0 }
      "- Map#{format('%03d', map_id)} | total=#{data[:total]} | translatable=#{data[:translated]}"
    }.join("\n")}
MD

puts "csv=#{OUTPUT_CSV}"
puts "summary=#{SUMMARY_MD}"
puts "coverage=#{coverage}"
