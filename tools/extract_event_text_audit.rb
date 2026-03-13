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
  def self._load(_str)
    new
  end
end

class Color
  def self._load(_str)
    new
  end
end

class Table
  def self._load(_str)
    new
  end
end

class Rect
  def self._load(_str)
    new
  end
end

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
SOURCE_DATA = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ENG)/Data")
TRACKING_DIR = ROOT.join("tracking")
CSV_PATH = TRACKING_DIR.join("event_text_audit.csv")
SUMMARY_PATH = TRACKING_DIR.join("event_text_summary.md")

TEXT_CODES = {
  101 => "show_text",
  102 => "choices",
  108 => "comment",
  355 => "script",
  401 => "show_text_cont",
  402 => "choice_branch",
  405 => "scroll_text",
  408 => "comment_cont",
  655 => "script_cont"
}.freeze

def normalize_text(value)
  return nil if value.nil?
  text = value.to_s.dup
  text = text.force_encoding("UTF-8") if text.encoding == Encoding::ASCII_8BIT
  text = text.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
  text = text.gsub(/\r\n?/, "\n").strip
  return nil if text.empty?
  text
end

def normalize_scalar(value)
  return nil if value.nil?
  return normalize_text(value) if value.is_a?(String)
  value
end

def extract_from_command(command)
  code = command.instance_variable_get(:@code)
  params = command.instance_variable_get(:@parameters) || []
  kind = TEXT_CODES[code]
  return [] unless kind

  case code
  when 101, 401, 405, 108, 408, 355, 655
    text = normalize_text(params[0])
    text ? [[kind, text]] : []
  when 102
    choices = params[0].is_a?(Array) ? params[0] : []
    choices.filter_map do |choice|
      text = normalize_text(choice)
      text ? [kind, text] : nil
    end
  when 402
    text = normalize_text(params[1])
    text ? [[kind, text]] : []
  else
    []
  end
end

def load_rxdata(path)
  Marshal.load(File.binread(path))
end

rows = []
summary = {
  common_events: 0,
  common_event_rows: 0,
  maps: 0,
  map_events: 0,
  map_pages: 0,
  map_rows: 0
}

common_events = load_rxdata(SOURCE_DATA.join("CommonEvents.rxdata"))
common_events.compact.each do |common_event|
  summary[:common_events] += 1
  list = common_event.instance_variable_get(:@list) || []
  list.each_with_index do |command, index|
    extract_from_command(command).each do |kind, text|
      rows << [
        "common_event",
        common_event.instance_variable_get(:@id),
        normalize_scalar(common_event.instance_variable_get(:@name)),
        nil,
        nil,
        nil,
        index,
        command.instance_variable_get(:@code),
        kind,
        text
      ]
      summary[:common_event_rows] += 1
    end
  end
end

map_paths = Dir.glob(SOURCE_DATA.join("Map[0-9][0-9][0-9].rxdata").to_s).sort
summary[:maps] = map_paths.length

map_paths.each do |map_path|
  map_id = File.basename(map_path)[/\d+/].to_i
  map = load_rxdata(map_path)
  events = map.instance_variable_get(:@events) || {}
  events.values.compact.each do |event|
    summary[:map_events] += 1
    pages = event.instance_variable_get(:@pages) || []
    pages.each_with_index do |page, page_index|
      summary[:map_pages] += 1
      list = page.instance_variable_get(:@list) || []
      list.each_with_index do |command, index|
        extract_from_command(command).each do |kind, text|
          rows << [
            "map",
            map_id,
            nil,
            event.instance_variable_get(:@id),
            normalize_scalar(event.instance_variable_get(:@name)),
            page_index + 1,
            index,
            command.instance_variable_get(:@code),
            kind,
            text
          ]
          summary[:map_rows] += 1
        end
      end
    end
  end
end

FileUtils.mkdir_p(TRACKING_DIR)

CSV.open(CSV_PATH, "w", write_headers: true, headers: %w[
  source_type source_id source_name event_id event_name page command_index code kind text
]) do |csv|
  rows.each { |row| csv << row }
end

top_maps = rows
  .select { |row| row[0] == "map" }
  .group_by { |row| row[1] }
  .transform_values(&:count)
  .sort_by { |_map_id, count| -count }
  .first(15)

SUMMARY_PATH.write(<<~MD)
  # Event Text Summary

  - Common events scanned: #{summary[:common_events]}
  - Common event text rows: #{summary[:common_event_rows]}
  - Maps scanned: #{summary[:maps]}
  - Map events scanned: #{summary[:map_events]}
  - Map pages scanned: #{summary[:map_pages]}
  - Map text rows: #{summary[:map_rows]}
  - Total extracted rows: #{rows.length}

  ## Top Maps By Extracted Text Rows
  #{top_maps.map { |map_id, count| "- Map#{format('%03d', map_id)}: #{count}" }.join("\n")}
MD

puts "csv=#{CSV_PATH}"
puts "summary=#{SUMMARY_PATH}"
puts "rows=#{rows.length}"
