require "csv"
require "fileutils"
require "pathname"

module RPG
  class Map; end
  class AudioFile; end
  class Event; end
  class EventCommand; end
  class MoveRoute; end
  class MoveCommand; end
  class CommonEvent; end
end

class RPG::Event::Page; end
class RPG::Event::Page::Condition; end
class RPG::Event::Page::Graphic; end

class Tone
  def self._load(_str) = new
end

class Color
  def self._load(_str) = new
end

class Table
  def self._load(_str) = new
end

class Rect
  def self._load(_str) = new
end

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
SOURCE_DATA = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ENG)/Data")
TARGET_DATA = ROOT.join("Data")
TRACKING_DIR = ROOT.join("tracking")
CSV_PATH = TRACKING_DIR.join("opening_sequence_translation.csv")
SUMMARY_PATH = TRACKING_DIR.join("opening_sequence_injection_summary.md")
OPENING_MAP_IDS = [22, 42, 32, 76, 78, 79, 80, 83, 88, 90, 92].freeze

def load_rxdata(path)
  Marshal.load(File.binread(path))
end

def dump_rxdata(path, object)
  FileUtils.mkdir_p(path.dirname)
  File.binwrite(path, Marshal.dump(object))
end

def grouped_rows(rows)
  rows.group_by do |row|
    [row["source_type"], row["source_id"].to_i, row["event_id"].to_i, row["page"].to_i, row["command_index"].to_i, row["code"].to_i]
  end
end

rows = CSV.read(CSV_PATH, headers: true).select do |row|
  row["draft_status"] == "proofread_opening" && !row["draft_id"].to_s.empty?
end
groups = grouped_rows(rows)
updated_files = []
updated_rows = 0

common_events = load_rxdata(SOURCE_DATA.join("CommonEvents.rxdata"))
groups.select { |key, _| key[0] == "common_event" }.each do |(_type, source_id, _event_id, _page, command_index, code), grouped|
  common_event = common_events.compact.find { |entry| entry.instance_variable_get(:@id).to_i == source_id }
  next unless common_event
  list = common_event.instance_variable_get(:@list) || []
  command = list[command_index]
  next unless command
  params = command.instance_variable_get(:@parameters) || []
  replacements = grouped.map { |row| row["draft_id"] }
  case code
  when 101, 401, 405
    params[0] = replacements.first
    updated_rows += 1
  when 102
    params[0] = replacements
    updated_rows += replacements.length
  when 402
    params[1] = replacements.first
    updated_rows += 1
  end
  command.instance_variable_set(:@parameters, params)
end
common_events_target = TARGET_DATA.join("CommonEvents.rxdata")
dump_rxdata(common_events_target, common_events)
updated_files << common_events_target

OPENING_MAP_IDS.each do |map_id|
  map_path = SOURCE_DATA.join(format("Map%03d.rxdata", map_id))
  next unless map_path.exist?
  map = load_rxdata(map_path)
  events = map.instance_variable_get(:@events) || {}
  groups.select { |key, _| key[0] == "map" && key[1] == map_id }.each do |(_type, _source_id, event_id, page, command_index, code), grouped|
    event = events[event_id]
    next unless event
    page_obj = (event.instance_variable_get(:@pages) || [])[page - 1]
    next unless page_obj
    command = (page_obj.instance_variable_get(:@list) || [])[command_index]
    next unless command
    params = command.instance_variable_get(:@parameters) || []
    replacements = grouped.map { |row| row["draft_id"] }
    case code
    when 101, 401, 405
      params[0] = replacements.first
      updated_rows += 1
    when 102
      params[0] = replacements
      updated_rows += replacements.length
    when 402
      params[1] = replacements.first
      updated_rows += 1
    end
    command.instance_variable_set(:@parameters, params)
  end
  target_path = TARGET_DATA.join(format("Map%03d.rxdata", map_id))
  dump_rxdata(target_path, map)
  updated_files << target_path
end

SUMMARY_PATH.write(<<~MD)
  # Opening Sequence Injection Summary

  - Source CSV: `tracking/opening_sequence_translation.csv`
  - Injected status: `proofread_opening`
  - Target directory: `Data`
  - Files written: #{updated_files.size}
  - Rows injected: #{updated_rows}

  ## Injected Files
  #{updated_files.map { |path| "- `#{path.relative_path_from(ROOT)}`" }.join("\n")}
MD

puts "summary=#{SUMMARY_PATH}"
puts "files=#{updated_files.size}"
puts "rows=#{updated_rows}"
