require "pathname"
require_relative "translation_overrides"

ROOT = Pathname.new("C:/Users/miftakhul.rizky/Downloads/Pokemon Unbreakable Ties 4.9.1 (ID)")
TARGETS = [
  ROOT.join("Data/english.dat"),
  ROOT.join("Data/messages.dat")
].freeze

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

def deep_replace(value)
  case value
  when String
    MANUAL_TRANSLATIONS.fetch(value, value)
  when Array
    value.map { |entry| deep_replace(entry) }
  when OrderedHash
    result = OrderedHash.new
    value.keys.each { |key| result[key] = deep_replace(value[key]) }
    result
  when Hash
    value.each_with_object({}) { |(key, entry), result| result[key] = deep_replace(entry) }
  else
    value
  end
end

TARGETS.each do |path|
  next unless File.exist?(path)
  data = Marshal.load(File.binread(path))
  File.binwrite(path, Marshal.dump(deep_replace(data)))
  puts "proofread=#{path}"
end
