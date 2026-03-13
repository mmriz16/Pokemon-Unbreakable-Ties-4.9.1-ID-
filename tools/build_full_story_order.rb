require "csv"
require "pathname"

module RPG
  class MapInfo; end
end

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
ENG_DATA = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ENG)/Data")
TRACKING = ROOT.join("tracking")
CSV_PATH = TRACKING.join("story_order_full.csv")
MD_PATH = TRACKING.join("story_order_full.md")

# Opening sequence inferred from metadata Home + explicit intro map.
OPENING_SEQUENCE = [22, 42, 32, 76, 78, 79, 80, 83, 88, 90, 92].freeze

map_infos = Marshal.load(File.binread(ENG_DATA.join("MapInfos.rxdata")))
rows = map_infos.compact.map do |id, info|
  [
    id.to_i,
    info.instance_variable_get(:@order).to_i,
    info.instance_variable_get(:@parent_id).to_i,
    info.instance_variable_get(:@name).to_s
  ]
end

ordered_ids = rows.sort_by { |id, order, _parent, _name| [order, id] }.map(&:first)
full_story_order = OPENING_SEQUENCE + ordered_ids.reject { |id| OPENING_SEQUENCE.include?(id) }

rows_by_id = rows.each_with_object({}) do |row, result|
  result[row[0]] = row
end

CSV.open(CSV_PATH, "w", write_headers: true, headers: %w[story_index map_id order parent_id map_name]) do |csv|
  full_story_order.each_with_index do |map_id, index|
    row = rows_by_id[map_id]
    next unless row
    csv << [index + 1, row[0], row[1], row[2], row[3]]
  end
end

MD_PATH.write(<<~MD)
  # Full Story Order

  Urutan ini dipakai sebagai baseline kerja translasi story.
  Bagian awal di-override agar mengikuti flow pembukaan game yang terdeteksi dari `metadata.txt`.

  ## Opening Sequence
  #{OPENING_SEQUENCE.map.with_index(1) { |map_id, index|
      row = rows_by_id[map_id]
      "#{index}. Map#{format('%03d', map_id)} | #{row[3]} | order=#{row[1]}"
    }.join("\n")}

  ## Total Maps In Story Order
  - #{full_story_order.length}

  ## First 40 Maps In Order
  #{full_story_order.first(40).map.with_index(1) { |map_id, index|
      row = rows_by_id[map_id]
      "#{index}. Map#{format('%03d', map_id)} | #{row[3]} | order=#{row[1]} | parent=#{row[2]}"
    }.join("\n")}
MD

puts "csv=#{CSV_PATH}"
puts "md=#{MD_PATH}"
puts "total=#{full_story_order.length}"
