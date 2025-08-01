class EncounterManager
  attr :encounters, :map_layer, :encounters_completed, :combats_won

  def initialize
    $encounter_manager = self
    @encounters_pool = $ENCOUNTERS
    @choices = []
    @unique_encounters = Hash.new { |h, layer| h[layer] = [] }

    @encounter_map = [
      ["dracolisk"],
      [rand_encounter?(2), rand_encounter?(2), rand_encounter?(2)],
      [rand_encounter?(3), rand_encounter?(3), rand_encounter?(3)],
      [rand_encounter?(4), rand_encounter?(4)],
      [rand_encounter?(5), rand_encounter?(5), rand_encounter?(5)],
      [rand_encounter?(6), rand_encounter?(6)],
      ["alchemy_lab"]
    ]

    if ($files.save_data&.[]("map_layer")).to_i > 0
      ml_save = ($files.save_data&.[]("map_layer")).to_i
    else
      ml_save = 1
    end
    @map_layer = ml_save
    @encounters_completed = 0
    @combats_won = 0

    @encounters_completed =
      $files.save_data["encounters_completed"] if $files.save_data[
      "encounters_completed"
    ]
    @combats_won = $files.save_data["combats_won"] if $files.save_data[
      "combats_won"
    ]
  end

  def encounters_completed?
    @encounters_completed
  end

  def inc_encounters_completed
    $player.status_effects.each { |e| e.calc_duration }
    @encounters_completed += 1
    $files.save_data["encounters_completed"] = @encounters_completed
  end

  def inc_combats_won
    @combats_won += 1
    $files.save_data["combats_won"] = @combats_won
  end

  def calc_anodyne_earnings
    @combats_won * 100
  end

  def card!(id)
    EncounterCard.new(id)
  end

  def reset!
    @encounters_completed = 0
    @combats_won = 0
    @map_layer = 1
    $files.save_data["encounters_completed"] = @encounters_completed
    $files.save_data["combats_won"] = @combats_won
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

  def rand_encounter?(layer = nil)
    # only pick from those with chance > 0
    available = @encounters_pool.select { |id, data| data.chance > 0 }.keys

    if layer
      # subtract out any we've already used this layer
      candidates = available - @unique_encounters[layer]
      raise "No more unique encounters for layer #{layer}" if candidates.empty?

      pick = weighted_sample(candidates)
      @unique_encounters[layer] << pick
      pick
    else
      weighted_sample(available)
    end
  end

  def weighted_sample(ids)
    total = ids.sum { |id| @encounters_pool[id][:chance] }
    target = rand * total
    ids.each do |id|
      w = @encounters_pool[id][:chance]
      return id if target < w
      target -= w
    end
  end
end
