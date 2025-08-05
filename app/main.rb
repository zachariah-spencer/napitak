# frozen_string_literal: true

# top level classes
require_relative "game"
require_relative "globals"

# models (just player)
require_relative "models/player"

# components
require_relative "models/components/combat_stats_component"
require_relative "models/components/shout_component"
require_relative "models/components/status_effect"

# enemies
require_relative "models/enemies/enemy"
require_relative "models/enemies/wolf"
require_relative "models/enemies/wraith"
require_relative "models/enemies/dracolisk"
require_relative "models/enemies/sentinel"
require_relative "models/enemies/mawfiend"
require_relative "models/enemies/abyssal_tutorial"

# cards
require_relative "models/cards/card"
require_relative "models/cards/potion_card"
require_relative "models/cards/ingredient_card"
require_relative "models/cards/reward_card"
require_relative "models/cards/encounter_card"
require_relative "models/cards/recipe_card"
require_relative "models/cards/ingredient_generator_card"
require_relative "models/cards/trash_can_card"
require_relative "models/cards/shop_item_card"

# scenes
require_relative "scenes/scene"
require_relative "scenes/intro"
require_relative "scenes/combat"
require_relative "scenes/alchemy_table"
require_relative "scenes/alchemy_lab"
require_relative "scenes/rewards_screen"
require_relative "scenes/map"
require_relative "scenes/pause_menu"
require_relative "scenes/journal"
require_relative "scenes/run_summary"
require_relative "scenes/meta_shop"
require_relative "scenes/combat_tutorial"
require_relative "scenes/boss_rewards_screen"
require_relative "scenes/rp_encounter"
require_relative "scenes/shop"
require_relative "scenes/collection"

# services and manager classes
require_relative "services/deck"
require_relative "services/inventory"
require_relative "services/recipe_book"
require_relative "services/encounter_manager"
require_relative "services/files"
require_relative "services/animation_manager"
require_relative "services/announcement_manager"
require_relative "services/card_hand_manager"
require_relative "services/enemy_ai"
require_relative "services/tutorial_service"
require_relative "services/event_bus"
require_relative "services/combo_manager"

# utilities and helper classes
# (some of these could be models but are so small and self contained that they are here instead)
require_relative "utils/json"
require_relative "utils/game_utils"
require_relative "utils/hash_order_utils"
require_relative "utils/scroll_list_widget"
require_relative "utils/scroll_list_widget_h"
require_relative "utils/upgrade_level_bar_widget"
require_relative "utils/button"
require_relative "utils/announcement"
require_relative "utils/transition"
require_relative "utils/status_effect_list_widget"

def tick(args)
  $files ||= Files.new
  $game ||= Game.new
  $game.args ||= args
  $game.tick if $game != nil
end

# reset is a top-level function that DR is aware of
# and will be invoked before GTK.reset occurs.
def reset(_args)
  # A new rng will be used GTK.reset is invoked
  GTK.set_rng (Time.now.to_f * 100).to_i
end
GTK.reset
