require_relative "game"
require_relative "globals"
require_relative "json"

require_relative "models/enemy"
require_relative "models/player"
require_relative "models/card"
require_relative "models/potion_card"
require_relative "models/ingredient_card"
require_relative "models/ingredient_reward_card"
require_relative "models/encounter_card"
require_relative "models/info_box"
require_relative "models/info_box_chain"
require_relative "models/recipe_card"

require_relative "services/deck"
require_relative "services/inventory"
require_relative "services/recipe_book"
require_relative "services/encounter_manager"
require_relative "services/files"

require_relative "scenes/combat"
require_relative "scenes/alchemy_table"
require_relative "scenes/alchemy_lab"
require_relative "scenes/rewards_screen"
require_relative "scenes/map"
require_relative "scenes/pause_menu"
require_relative "scenes/journal"
require_relative "scenes/run_summary"

class Hash
  def front(key)
    if !key?(key)
      raise "Hash.front(key): key passed in as argument is not found in the hash"
    end
    value = delete(key)
    # Build a new hash with the one pair first, then the rest:
    replace({ key => value }.merge(self))
    self
  end

  def back(key)
    if !key?(key)
      raise "Hash.back(key): key passed in as argument is not found in the hash"
    end
    value = delete(key)
    self[key] = value
    self
  end
end

def tick(args)
  $files ||= Files.new

  # GTK.on_tick_count(Kernel.tick_count + 60) do
  $game ||= Game.new
  $game.args ||= args
  # end

  $game.tick if $game != nil
end

# reset is a top-level function that DR is aware of
# and will be invoked before GTK.reset occurs.
def reset(_args)
  # A new rng will be used GTK.reset is invoked
  GTK.set_rng (Time.now.to_f * 100).to_i
end
GTK.reset_next_tick()
