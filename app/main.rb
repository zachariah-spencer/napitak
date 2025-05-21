require_relative 'game.rb'
require_relative 'globals.rb'

require_relative 'models/enemy.rb'
require_relative 'models/player.rb'
require_relative 'models/card.rb'

require_relative 'services/deck.rb'
require_relative 'services/inventory.rb'
require_relative 'services/recipe_book.rb'

require_relative 'scenes/combat.rb'
require_relative 'scenes/alchemy_table.rb'

def tick args
  $game ||= Game.new
  $game.args ||= args

  $game.tick
end

# reset is a top-level function that DR is aware of
# and will be invoked before GTK.reset occurs.
def reset args
  # A new rng will be used GTK.reset is invoked
  GTK.set_rng (Time.now.to_f * 100).to_i
end
GTK.reset_next_tick