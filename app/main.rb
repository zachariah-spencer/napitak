require_relative "game"
require_relative "globals"

require_relative "models/enemy"
require_relative "models/player"
require_relative "models/card"
require_relative "models/potion_card"
require_relative "models/ingredient_card"
require_relative "models/ingredient_reward_card"

require_relative "services/deck"
require_relative "services/inventory"
require_relative "services/recipe_book"

require_relative "scenes/combat"
require_relative "scenes/alchemy_table"
require_relative "scenes/rewards_screen"

def tick(args)
  $game ||= Game.new
  $game.args ||= args

  $game.tick
end

# reset is a top-level function that DR is aware of
# and will be invoked before GTK.reset occurs.
def reset(_args)
  # A new rng will be used GTK.reset is invoked
  GTK.set_rng (Time.now.to_f * 100).to_i
end
GTK.reset_next_tick
