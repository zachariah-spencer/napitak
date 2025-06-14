class Files
  attr_gtk
  attr :save_data

  def initialize
    # The hash to manipulate save data on during runtime
    # @save_data = {}

    read_hash = read
    @save_data = (read_hash == nil or read_hash == "") ? {} : read_hash
  end

  def write()
    json = to_json(@save_data)
    GTK.write_file("data/save_data.json", json)
  end

  def read()
    json = GTK.read_file("data/save_data.json")
    return {} unless json # Return empty hash if file doesn't exist

    GTK.parse_json(json)
  end

  def to_json(hash)
    entries = hash.map do |k, v|
      key = "\"#{k}\""
      value = case v
              when String then "\"#{v}\""
              when Array  then "[" + v.map { |e| "\"#{e}\"" }.join(", ") + "]"
              when Hash   then to_json_like(v)
              else v.to_s
              end
      "#{key}: #{value}"
    end
    "{#{entries.join(', ')}}"
  end
end
