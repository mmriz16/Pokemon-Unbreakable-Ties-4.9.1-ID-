require "json"
require "net/http"
require "pathname"
require "uri"

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
SOURCE_ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ENG)")
SOURCE_ENGLISH = SOURCE_ROOT.join("Data/english.dat")
OUTPUT_ENGLISH = ROOT.join("Data/english.dat")
CACHE_PATH = ROOT.join("tools/english_dat_translate_cache.json")

TRANSLATE_ARRAYS = [
  2,   # Kinds
  3,   # Entries
  6,   # MoveDescriptions
  9,   # ItemDescriptions
  11,  # AbilityDescs
  12,  # Types
  13,  # TrainerTypes
  18,  # RegionNames
  25,  # RibbonNames
  26   # RibbonDescriptions
].freeze

TRANSLATE_HASHES = [
  0,   # Common/map messages
  14,  # TrainerNames
  15,  # BeginSpeech
  16,  # EndSpeechWin
  17,  # EndSpeechLose
  19,  # PlaceNames
  20,  # PlaceDescriptions
  22,  # PhoneMessages
  23,  # TrainerLoseText
  24   # ScriptTexts
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
  "Pokémon" => "Pokemon",
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

class OrderedHash < Hash
end

OrderedHash.define_singleton_method(:_load) do |str|
  obj = allocate
  obj.instance_variable_set(:@_raw_load, str)
  obj
end

OrderedHash.class_eval do
  def _dump(_level)
    if instance_variable_defined?(:@_raw_load) && empty?
      instance_variable_get(:@_raw_load)
    else
      Marshal.dump(Hash[self])
    end
  end
end

def load_cache
  return {} unless File.exist?(CACHE_PATH)
  JSON.parse(File.read(CACHE_PATH, encoding: "UTF-8"))
end

def save_cache(cache)
  File.write(CACHE_PATH, JSON.pretty_generate(cache), mode: "w", encoding: "UTF-8")
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
  text = text.gsub("Pokémon", "Pokemon")
  text = text.gsub("Permainan", "Game")
  text = text.gsub(/\s+/, " ").strip unless text.include?("\n")
  text
end

def translatable?(text)
  return false if text.nil?
  return false if text == ""
  return false if text.match?(/\A[0-9]+\z/)
  true
end

def request_translate(text)
  uri = URI("https://translate.googleapis.com/translate_a/single")
  params = {
    client: "gtx",
    sl: "en",
    tl: "id",
    dt: "t",
    q: text
  }
  uri.query = URI.encode_www_form(params)
  response = Net::HTTP.get_response(uri)
  raise "translate http #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  payload = JSON.parse(response.body)
  payload[0].map { |entry| entry[0] }.join
end

def translate_text(text, cache)
  return text unless translatable?(text)
  return MANUAL[text] if MANUAL.key?(text)
  return cache[text] if cache.key?(text)
  protected, replacements = protect_tokens(text)
  translated = nil
  3.times do
    begin
      translated = request_translate(protected)
      break
    rescue StandardError
      sleep 2
    end
  end
  translated = text if translated.nil? || translated.empty?
  translated = restore_tokens(translated, replacements)
  translated = normalize_translation(translated)
  cache[text] = translated
  translated
end

def translate_array!(arr, cache)
  arr.each_with_index do |value, idx|
    next if idx == 0 && value == ""
    next unless value.is_a?(String)
    arr[idx] = translate_text(value, cache)
  end
end

def translate_hash_like!(obj, cache)
  return obj unless obj.respond_to?(:each_pair)
  obj.keys.each do |key|
    value = obj[key]
    case value
    when String
      obj[key] = translate_text(value, cache)
    when Array
      value.map!.with_index do |entry, idx|
        entry.is_a?(String) ? translate_text(entry, cache) : entry
      end
    when Hash, OrderedHash
      translate_hash_like!(value, cache)
    end
  end
  obj
end

cache = load_cache
data = Marshal.load(File.binread(SOURCE_ENGLISH))

data.each_with_index do |entry, idx|
  next if KEEP_AS_IS.include?(idx)
  if TRANSLATE_ARRAYS.include?(idx) && entry.is_a?(Array)
    translate_array!(entry, cache)
  elsif TRANSLATE_HASHES.include?(idx)
    case entry
    when Array
      entry.each do |sub|
        translate_hash_like!(sub, cache) if sub.is_a?(Hash) || sub.is_a?(OrderedHash)
      end
    when Hash, OrderedHash
      translate_hash_like!(entry, cache)
    end
  end
  save_cache(cache) if idx % 2 == 0
end

File.binwrite(OUTPUT_ENGLISH, Marshal.dump(data))
save_cache(cache)
puts "written=#{OUTPUT_ENGLISH}"
