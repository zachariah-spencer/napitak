class Files
  attr_gtk
  attr :save_data

  def initialize
    # The hash to manipulate save data on during runtime
    @save_data = {}
    read_hash = read
    @save_data = read_hash if read_hash != nil and read_hash != ""
    @save_data["player"] = {} unless save_data["player"]
    @save_data["settings"] = {} unless save_data["settings"]
    @save_data["player"]["upgrades"] = {} unless save_data["player"]["upgrades"]
    @save_data["player"]["run_upgrades"] = {} unless save_data["player"]["run_upgrades"]
    @save_data["player"]["status_effects"] = [] unless save_data["player"]["status_effects"]
    @save_data["tutorials"] = {} unless save_data["tutorials"]
  end

  def write()
    json = @save_data.to_json
    GTK.write_file("data/save_data.json", json)
  end

  def read()
    json = GTK.read_file("data/save_data.json")
    return {} unless json # Return empty hash if file doesn't exist

    GTK.parse_json(json)
  end
end
