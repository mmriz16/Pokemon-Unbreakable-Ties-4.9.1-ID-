require "json"
require "net/http"
require "pathname"
require "uri"

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
SOURCE_ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ENG)")
SOURCE_MESSAGES = SOURCE_ROOT.join("Data/messages.dat")
OUTPUT_MESSAGES = ROOT.join("Data/messages.dat")
TEMP_MESSAGES = ROOT.join("Data/messages.dat.tmp")
CACHE_PATH = ROOT.join("tools/messages_dat_translate_cache.json")
STATE_PATH = ROOT.join("tools/messages_dat_translate_state.json")
ENGLISH_CACHE_PATH = ROOT.join("tools/english_dat_translate_cache.json")
FAILURE_LOG_PATH = ROOT.join("tools/messages_dat_translate_failures.log")

TRANSLATE_SECTIONS = [
  0,   # Common/map messages
  2,   # Kinds
  3,   # Entries
  6,   # MoveDescriptions
  9,   # ItemDescriptions
  11,  # AbilityDescs
  12,  # Types
  13,  # TrainerTypes
  14,  # TrainerNames
  15,  # BeginSpeech
  16,  # EndSpeechWin
  17,  # EndSpeechLose
  18,  # RegionNames
  19,  # PlaceNames
  20,  # PlaceDescriptions
  22,  # PhoneMessages
  23,  # TrainerLoseText
  24,  # ScriptTexts
  25,  # RibbonNames
  26   # RibbonDescriptions
].freeze

KEEP_AS_IS = [
  1,   # Species
  4,   # FormNames
  5,   # Moves
  7,   # Items
  8,   # ItemPlurals
  10,  # Abilities
  21   # MapNames
].freeze

MANUAL = {
  "Pokemon" => "Pokemon",
  "PokÃ©mon" => "Pokemon",
  "Yes" => "Ya",
  "No" => "Tidak",
  "Cancel" => "Batal",
  "Save" => "Simpan",
  "Options" => "Opsi",
  "Bag" => "Tas",
  "Quit Game" => "Keluar dari Game",
  "Close" => "Tutup",
  "Level" => "Level",
  "None" => "Tidak ada"
}.freeze

TOKEN_RE = /(\{[0-9]+\}|\\[nrt]|\\PN|\\v\[[0-9]+\]|\\wt\[[0-9]+\]|\\[A-Z]{1,3}|<[^>]+>)/
CHECKPOINT_INTERVAL = 10
BATCH_SIZE = 20

class OrderedHash < Hash
  def initialize
    @keys = []
    super
  end

  def keys
    @keys.clone
  end

  def []=(key, value)
    oldvalue = self[key]
    if !oldvalue && value
      @keys.push(key)
    elsif !value
      @keys |= []
      @keys -= [key]
    end
    super(key, value)
  end

  def self._load(string)
    ret = new
    keysvalues = Marshal.load(string)
    keys = keysvalues[0]
    values = keysvalues[1]
    keys.each_with_index { |key, i| ret[key] = values[i] }
    ret
  end

  def _dump(_depth = 100)
    values = []
    @keys.each { |key| values << self[key] }
    Marshal.dump([@keys, values])
  end
end

def load_json(path)
  return {} unless File.exist?(path)
  JSON.parse(File.read(path, encoding: "UTF-8"))
end

def save_json(path, object)
  File.write(path, JSON.pretty_generate(object), mode: "w", encoding: "UTF-8")
end

def load_cache
  cache = load_json(ENGLISH_CACHE_PATH)
  messages_cache = load_json(CACHE_PATH)
  cache.merge(messages_cache)
end

def save_checkpoint(data, cache, state)
  File.binwrite(TEMP_MESSAGES, Marshal.dump(data))
  save_json(CACHE_PATH, cache)
  save_json(STATE_PATH, state)
end

def protect_tokens(text)
  replacements = {}
  protected = text.gsub(TOKEN_RE) do |token|
    key = "__TOK_#{replacements.length}__"
    replacements[key] = token
    key
  end
  [protected, replacements]
end

def restore_tokens(text, replacements)
  replacements.each { |key, value| text = text.gsub(key, value) }
  text
end

def normalize_translation(text)
  return "" if text.nil?
  text = text.gsub("Pok?mon", "Pokemon")
  text = text.gsub("PokÃ©mon", "Pokemon")
  text = text.gsub("Permainan", "Game")
  text = text.gsub(/\s+/, " ").strip unless text.include?("\n")
  text
end

def translatable?(text)
  return false if text.nil?
  return false if text == ""
  return false if text.match?(/\A[0-9]+\z/)
  return false if text.match?(/\A[:A-Z0-9_]+\z/)
  true
end

def log_failure(text, error)
  File.open(FAILURE_LOG_PATH, "a:utf-8") do |file|
    file.puts("[#{Time.now}] #{error.class}: #{error.message}")
    file.puts(text)
    file.puts("---")
  end
end

def fetch_translation(text)
  uri = URI("https://translate.googleapis.com/translate_a/single")
  uri.query = URI.encode_www_form(
    client: "gtx",
    sl: "auto",
    tl: "id",
    dt: "t",
    q: text
  )
  response = Net::HTTP.get_response(uri)
  raise "translate failed for #{text.inspect}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  payload = JSON.parse(response.body)
  payload[0].map { |part| part[0] }.join
end

def translate_batch(texts, cache)
  missing = texts.uniq.select { |text| translatable?(text) && !MANUAL.key?(text) && !cache.key?(text) }
  missing.each_slice(BATCH_SIZE) do |slice|
    joined = slice.each_with_index.map { |text, i| "<BATCH#{i}>#{text}" }.join("\n")
    protected, replacements = protect_tokens(joined)
    begin
      translated = fetch_translation(protected)
      translated = restore_tokens(translated, replacements)
      translated.scan(/<BATCH(\d+)>(.*?)(?=<BATCH\d+>|$)/m).each do |index, body|
        original = slice[index.to_i]
        cache[original] = normalize_translation(body.strip)
      end
      slice.each { |text| cache[text] ||= text }
    rescue StandardError => error
      slice.each do |text|
        log_failure(text, error)
        cache[text] = text
      end
    end
  end
end

def translate_text(text, cache)
  return text unless translatable?(text)
  return MANUAL[text] if MANUAL.key?(text)
  return cache[text] if cache.key?(text)

  protected, replacements = protect_tokens(text)
  begin
    translated = fetch_translation(protected)
    translated = restore_tokens(translated, replacements)
    translated = normalize_translation(translated)
    cache[text] = translated
    translated
  rescue StandardError => error
    log_failure(text, error)
    cache[text] = text
    text
  end
end

def collect_strings(value, result = [])
  case value
  when String
    result << value if translatable?(value)
  when Array
    value.each { |entry| collect_strings(entry, result) }
  when OrderedHash
    value.keys.each { |key| collect_strings(value[key], result) }
  when Hash
    value.each_value { |entry| collect_strings(entry, result) }
  end
  result
end

def deep_translate(value, cache)
  case value
  when String
    translate_text(value, cache)
  when Array
    value.map { |entry| deep_translate(entry, cache) }
  when OrderedHash
    translated = OrderedHash.new
    value.keys.each { |key| translated[key] = deep_translate(value[key], cache) }
    translated
  when Hash
    value.each_with_object({}) do |(key, entry), result|
      result[key] = deep_translate(entry, cache)
    end
  else
    value
  end
end

cache = load_cache
state = load_json(STATE_PATH)
data = if File.exist?(TEMP_MESSAGES)
  Marshal.load(File.binread(TEMP_MESSAGES))
else
  Marshal.load(File.binread(SOURCE_MESSAGES))
end

TRANSLATE_SECTIONS.each do |idx|
  next if KEEP_AS_IS.include?(idx)
  next if state["sections_done"]&.include?(idx)

  section = data[idx]
  if idx == 0 && section.is_a?(Array)
    start_at = state["section_0_index"] || 0
    while start_at < section.length
      translate_batch(collect_strings(section[start_at]), cache)
      section[start_at] = deep_translate(section[start_at], cache)
      start_at += 1
      state["section_0_index"] = start_at
      if (start_at % CHECKPOINT_INTERVAL).zero?
        puts "checkpoint section=0 index=#{start_at}"
        save_checkpoint(data, cache, state)
      end
    end
    state.delete("section_0_index")
  else
    translate_batch(collect_strings(section), cache)
    data[idx] = deep_translate(section, cache)
  end

  state["sections_done"] ||= []
  state["sections_done"] << idx
  state["sections_done"].uniq!
  puts "section_done=#{idx}"
  save_checkpoint(data, cache, state)
end

File.binwrite(OUTPUT_MESSAGES, Marshal.dump(data))
File.delete(TEMP_MESSAGES) if File.exist?(TEMP_MESSAGES)
File.delete(STATE_PATH) if File.exist?(STATE_PATH)
save_json(CACHE_PATH, cache)
puts "written=#{OUTPUT_MESSAGES}"
