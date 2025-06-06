class EncounterManager
  attr :encounters

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
    @map_layer = 1
    @encounters_completed = 0
  end

  def encounters_completed?
    @encounters_completed
  end

  def inc_encounters_completed
    @encounters_completed += 1
  end

  def card!(id)
    EncounterCard.new(id)
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
    e_layer.each do |enc_id|
      enc_cards << card!(enc_id)
    end

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
