require_relative 'card.rb'
require_relative 'globals.rb'
require_relative 'enemy.rb'
require_relative 'game.rb'
require_relative 'player.rb'
require_relative 'deck.rb'
require_relative 'inventory.rb'

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