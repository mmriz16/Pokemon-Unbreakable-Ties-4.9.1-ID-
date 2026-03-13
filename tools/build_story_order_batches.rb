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
SUMMARY_MD = TRACKING.join("story_order_priority.md")
BATCH_DIR = TRACKING.join("story_batches")

# Story order inferred from metadata Home start + MapInfos ordering for the opening route.
STORY_MAP_IDS = [22, 42, 32, 76, 78, 79, 80, 83, 88, 90, 92].freeze

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

FileUtils.mkdir_p(BATCH_DIR)

story_rows = {}
STORY_MAP_IDS.each do |map_id|
  entries = map_rows.select { |row| row["source_id"].to_i == map_id }
  story_rows[map_id] = entries
  name = map_names[map_id] || "Map#{format('%03d', map_id)}"
  filename = format("Map%03d_%s.csv", map_id, safe_name(name))
  CSV.open(BATCH_DIR.join(filename), "w", write_headers: true, headers: rows.headers) do |csv|
    entries.each { |row| csv << row }
  end
end

SUMMARY_MD.write(<<~MD)
  # Story Order Priority

  Backlog ini mengurutkan batch translasi berdasarkan alur story awal game, bukan berdasarkan jumlah teks terbanyak.

  ## Story Start Sequence
  #{STORY_MAP_IDS.map.with_index(1) { |map_id, index|
      name = map_names[map_id] || "Unknown"
      count = story_rows[map_id].length
      "#{index}. Map#{format('%03d', map_id)} | #{name} | #{count} row teks"
    }.join("\n")}

  ## Batch Files
  #{STORY_MAP_IDS.map { |map_id|
      name = map_names[map_id] || "Map#{format('%03d', map_id)}"
      "- `tracking/story_batches/#{format('Map%03d_%s.csv', map_id, safe_name(name))}`"
    }.join("\n")}
MD

puts "summary=#{SUMMARY_MD}"
puts "batch_dir=#{BATCH_DIR}"
