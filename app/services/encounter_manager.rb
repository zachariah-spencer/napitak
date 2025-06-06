class EncounterManager
  attr :encounters

  def initialize
    @encounters = ["alchemy_table", "combat"]
  end

  def rand_encounter?
    @encounters.sample
  end
end
