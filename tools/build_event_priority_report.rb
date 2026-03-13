require "csv"
require "fileutils"
require "pathname"

module RPG
  class MapInfo; end
end

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
ENG_DATA = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ENG)/Data")
TRACKING = ROOT.join("tracking")
AUDIT_CSV = TRACKING.join("event_text_audit.csv")
SUMMARY_MD = TRACKING.join("event_text_priority.md")
BATCH_DIR = TRACKING.join("event_batches")

def safe_name(text)
  text.to_s.gsub(/[^0-9A-Za-z_-]+/, "_").gsub(/_+/, "_").gsub(/\A_|_\z/, "")
end

map_infos = Marshal.load(File.binread(ENG_DATA.join("MapInfos.rxdata")))
map_names = map_infos.each_with_object({}) do |(id, info), result|
  next unless id && info
  result[id.to_i] = info.instance_variable_get(:@name)
end

rows = CSV.read(AUDIT_CSV, headers: true)
map_rows = rows.select { |row| row["source_type"] == "map" }
grouped = map_rows.group_by { |row| row["source_id"].to_i }
ranked = grouped.map { |map_id, entries| [map_id, entries.length] }.sort_by { |_map_id, count| -count }

FileUtils.mkdir_p(BATCH_DIR)

common_rows = rows.select { |row| row["source_type"] == "common_event" }
CSV.open(BATCH_DIR.join("common_events.csv"), "w", write_headers: true, headers: rows.headers) do |csv|
  common_rows.each { |row| csv << row }
end

ranked.first(15).each do |map_id, _count|
  map_name = map_names[map_id] || "Map#{format('%03d', map_id)}"
  filename = format("Map%03d_%s.csv", map_id, safe_name(map_name))
  CSV.open(BATCH_DIR.join(filename), "w", write_headers: true, headers: rows.headers) do |csv|
    grouped[map_id].each { |row| csv << row }
  end
end

SUMMARY_MD.write(<<~MD)
  # Event Text Priority

  Audit ini memecah `event_text_audit.csv` menjadi batch prioritas per map untuk translasi story berikutnya.

  ## Top 15 Maps By Extracted Text Rows
  #{ranked.first(15).map { |map_id, count|
      name = map_names[map_id] || "Unknown"
      "- Map#{format('%03d', map_id)} | #{name} | #{count}"
    }.join("\n")}

  ## Batch Files
  - `tracking/event_batches/common_events.csv`
  #{ranked.first(15).map { |map_id, _count|
      name = map_names[map_id] || "Map#{format('%03d', map_id)}"
      "- `tracking/event_batches/#{format('Map%03d_%s.csv', map_id, safe_name(name))}`"
    }.join("\n")}
MD

puts "summary=#{SUMMARY_MD}"
puts "batch_dir=#{BATCH_DIR}"
