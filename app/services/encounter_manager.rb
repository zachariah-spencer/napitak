class EncounterManager
  attr :encounters, :map_layer

  def initialize
    $encounter_manager = self
    @encounters_pool = $encounters
    @choices = []
    @encounter_map = [
                                      [rand_encounter?],
                      [rand_encounter?, rand_encounter?, rand_encounter?],
                      [rand_encounter?, rand_encounter?, rand_encounter?],
                              [rand_encounter?, rand_encounter?],
                      [rand_encounter?, rand_encounter?, rand_encounter?],
                              [rand_encounter?, rand_encounter?],
                                        ["alchemy_lab"]
                      ]

    if ($files.save_data&.[]("map_layer")).to_i > 0
      ml_save = ($files.save_data&.[]("map_layer")).to_i
    else
      ml_save = 1
    end
    @map_layer = ml_save
    @encounters_completed = 0
  end

  def encounters_completed?
    @encounters_completed
  end

  def inc_encounters_completed
    @encounters_completed += 1
    $files.save_data["encounters_completed"] = @encounters_completed
  end

  def card!(id)
    EncounterCard.new(id)
  end

  def reset
    @encounters_completed = 0
    @map_layer = 1
    $files.save_data["encounters_completed"] = @encounters_completed
    $files.save_data["map_layer"] = @map_layer
  end

  def next_choices?
    last_layer = 6
    first_layer = 2

    e_layer = @encounter_map[@encounter_map.size - @map_layer]
    if @map_layer <= last_layer
      @map_layer += 1
    else
      @map_layer = first_layer
    end

    enc_cards = []
    enc_ids = []
    e_layer.each do |enc_id|
      enc_cards << card!(enc_id)
      enc_ids << enc_id

    end

    $files.save_data["map_choices"] = enc_ids
    @choices = enc_cards
  end

  def choices?
    @choices
  end

  def rand_encounter?
    e = @encounters_pool.keys.sample
    while @encounters_pool[e].chance == 0
      e = @encounters_pool.keys.sample
    end

    e
  end
end
