require "csv"
require "json"
require "net/http"
require "pathname"
require "uri"

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
TRACKING = ROOT.join("tracking")
AUDIT_CSV = TRACKING.join("event_text_audit.csv")
ORDER_CSV = TRACKING.join("story_order_full.csv")
OUTPUT_CSV = TRACKING.join("story_translation_draft.csv")
SUMMARY_MD = TRACKING.join("story_translation_draft_summary.md")
CACHE_PATH = ROOT.join("tools/story_translate_cache.json")

TRANSLATABLE_KINDS = %w[show_text show_text_cont choices choice_branch scroll_text].freeze
BATCH_SIZE = 40
SEPARATOR = "\n__CODEXSEP__\n"
TOKEN_PATTERN = /
  \\[A-Za-z_]+(?:\[[^\]]*\])? |
  <[^>]+>
/x.freeze

def load_cache
  return {} unless File.exist?(CACHE_PATH)
  cache = JSON.parse(File.read(CACHE_PATH))
  cache.reject { |_key, value| value.to_s.match?(/KODEXTOK|CODEXTOK/) }
rescue JSON::ParserError
  {}
end

def save_cache(cache)
  File.write(CACHE_PATH, JSON.pretty_generate(cache))
end

def normalize_text(text)
  value = text.to_s.dup
  value = value.force_encoding("UTF-8") if value.encoding == Encoding::ASCII_8BIT
  value.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
end

def protect_tokens(text)
  tokens = []
  protected = normalize_text(text).gsub(TOKEN_PATTERN) do |match|
    placeholder = "§§#{tokens.length}§§"
    tokens << match
    placeholder
  end
  [protected, tokens]
end

def restore_tokens(text, tokens)
  restored = text.dup
  tokens.each_with_index do |token, idx|
    restored = restored.gsub("§§#{idx}§§", token)
  end
  restored
end

def translate_request(strings)
  payload = strings.join(SEPARATOR)
  q = URI.encode_www_form_component(payload)
  uri = URI("https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=id&dt=t&q=#{q}")
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 20, read_timeout: 60) do |http|
    http.get(uri.request_uri).body
  end
  data = JSON.parse(response)
  translated = data[0].map { |entry| entry[0] }.join
  translated.split(SEPARATOR, -1)
end

def translate_request_with_retry(strings, retries: 3)
  attempts = 0
  begin
    attempts += 1
    translate_request(strings)
  rescue Net::OpenTimeout, Net::ReadTimeout, JSON::ParserError
    raise if attempts >= retries
    sleep(2 * attempts)
    retry
  end
end

def translate_with_cache(strings, cache)
  pending = strings.uniq.reject { |text| cache.key?(text) }
  protected_map = {}

  pending.each do |text|
    protected_map[text] = protect_tokens(text)
  end

  pending.each_slice(BATCH_SIZE) do |slice|
    protected_batch = slice.map { |text| protected_map[text][0] }
    translated_batch = translate_request_with_retry(protected_batch)
    if translated_batch.length != slice.length
      translated_batch = protected_batch.map do |entry|
        begin
          translate_request_with_retry([entry]).first
        rescue Net::OpenTimeout, Net::ReadTimeout, JSON::ParserError
          entry
        end
      end
    end
    slice.each_with_index do |original, idx|
      translated = translated_batch[idx] || protected_batch[idx]
      cache[original] = restore_tokens(translated, protected_map[original][1])
    end
    save_cache(cache)
  end
end

order_rows = CSV.read(ORDER_CSV, headers: true)
story_order = order_rows.each_with_object({}) do |row, result|
  result[row["map_id"].to_i] = row["story_index"].to_i
end

audit_rows = CSV.read(AUDIT_CSV, headers: true)

translatable_texts = audit_rows.filter_map do |row|
  next unless row["source_type"] == "common_event" || story_order.key?(row["source_id"].to_i)
  next unless TRANSLATABLE_KINDS.include?(row["kind"])
  text = row["text"].to_s.strip
  next if text.empty?
  text
end

cache = load_cache
translate_with_cache(translatable_texts, cache)

headers = audit_rows.headers + ["story_index", "draft_id", "draft_status"]

CSV.open(OUTPUT_CSV, "w", write_headers: true, headers: headers) do |csv|
  audit_rows.each do |row|
    source_type = row["source_type"]
    source_id = row["source_id"].to_i
    story_index = source_type == "map" ? story_order[source_id] : 0

    next if source_type == "map" && story_index.nil?

    text = row["text"].to_s
    draft_id = nil
    status = "skip_non_text"

    if TRANSLATABLE_KINDS.include?(row["kind"])
      draft_id = cache[text.strip] || text
      status = "machine_draft"
    elsif row["kind"].to_s.start_with?("comment")
      status = "skip_comment"
    elsif row["kind"] == "script" || row["kind"] == "script_cont"
      status = "skip_script"
    end

    csv << row.fields + [story_index, draft_id, status]
  end
end

machine_draft_count = 0
common_event_count = 0
map_count = 0
CSV.foreach(OUTPUT_CSV, headers: true) do |row|
  machine_draft_count += 1 if row["draft_status"] == "machine_draft"
  common_event_count += 1 if row["source_type"] == "common_event"
  map_count += 1 if row["source_type"] == "map"
end

SUMMARY_MD.write(<<~MD)
  # Story Translation Draft Summary

  - Output: `tracking/story_translation_draft.csv`
  - Machine drafted text rows: #{machine_draft_count}
  - Common event rows included: #{common_event_count}
  - Story-order map rows included: #{map_count}
  - Story maps covered: #{story_order.length}

  ## Notes
  - Draft ini adalah baseline otomatis untuk seluruh jalur story.
  - Row dengan `draft_status=machine_draft` sudah punya terjemahan awal.
  - Row `skip_script` dan `skip_comment` tidak diterjemahkan karena bukan dialog pemain langsung.
MD

puts "output=#{OUTPUT_CSV}"
puts "summary=#{SUMMARY_MD}"
puts "cache=#{CACHE_PATH}"
