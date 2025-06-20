# frozen_string_literal: true

class Player
  attr_gtk
  attr :ingredients,
       :potions,
       :focus,
       :max_focus,
       :hp,
       :max_hp,
       :stunned_turns,
       :hovered_cards,
       :died,
       :combat_stats,
       :my_turn,
       :anodyne,
       :starting_inventory_size,
       :maximum_focus,
       :maximum_hp,
       :alchemy_table_uses,
       :shop_discount,
       :reward_picks

  def initialize
    $player = self

    # meta-progression upgrades and currency vars
    @anodyne = 1000
    @starting_inventory_size = 5
    @maximum_focus = 2
    @maximum_hp = 10
    @alchemy_table_uses = 1
    @shop_discount = 0 # out of 100 (integer percentile)
    @reward_picks = 2

    @my_turn = true
    @combat_stats = CombatStatsComponent.new(hp: 20, focus: 4, x: 300, y: 25)
    @stunned_turns = 0
    @hovered_cards = []
    @died = false


    @ingredients = Inventory.new()
    @potions = Inventory.new()
  end

  def reset!
    @ingredients = Inventory.new()
    @potions = Inventory.new()
    @combat_stats.validate_upgrades(@maximum_hp, @maximum_focus)
    @combat_stats.reset!
    @died = false
    @my_turn = true

    save_upgrades_data
    save_inventory_data
  end

  def save_inventory_data
    potions_save_data = []
    ingredients_save_data = []
    @potions.all_cards.each { |c| potions_save_data << c.save_data? }
    @ingredients.all_cards.each { |c| ingredients_save_data << c.save_data? }

    $files.save_data["player"]["potions"] = potions_save_data
    $files.save_data["player"]["ingredients"] = ingredients_save_data
  end

  def save_upgrades_data
    $files.save_data["player"]["upgrades"]["anodyne"] = @anodyne
    $files.save_data["player"]["upgrades"]["starting_inventory_size"] = @starting_inventory_size
    $files.save_data["player"]["upgrades"]["maximum_focus"] = @maximum_focus
    $files.save_data["player"]["upgrades"]["maximum_hp"] = @maximum_hp
    $files.save_data["player"]["upgrades"]["alchemy_table_uses"] = @alchemy_table_uses
    $files.save_data["player"]["upgrades"]["shop_discount"] = @shop_discount
    $files.save_data["player"]["upgrades"]["reward_picks"] = @reward_picks
  end

  def load_inventory_data
    if $files.save_data["player"]["potions"]
      $files.save_data["player"]["potions"].each do |data|
        id = data["id"]
        uses = data["uses_left"].to_i
        @player.potions.add(
          PotionCard.new(
            id,
            GameUtils.new_id?,
            $pids[id].name,
            $pids[id].fc,
            $pids[id].path,
            $pids[id].max_uses,
            uses_left: uses
          )
        )
      end
    end

    if $files.save_data["player"]["ingredients"]
      $files.save_data["player"]["ingredients"].each do |id|
        @player.ingredients.add(
          IngredientCard.new(
            id,
            GameUtils.new_id?,
            $iids[id].name,
            -1,
            $iids[id].path
          )
        )
      end
    end
  end

  def load_upgrades_data
    # Always saved and loaded as a group so if "starting_inventory_size" exists then a save file exists as well.
    if $files.save_data["player"]["upgrades"]["anodyne"]
      @anodyne = $files.save_data["player"]["upgrades"]["anodyne"]
      @starting_inventory_size = $files.save_data["player"]["upgrades"]["starting_inventory_size"]
      @maximum_focus = $files.save_data["player"]["upgrades"]["maximum_focus"]
      @maximum_hp = $files.save_data["player"]["upgrades"]["maximum_hp"]
      @alchemy_table_uses = $files.save_data["player"]["upgrades"]["alchemy_table_uses"]
      @shop_discount = $files.save_data["player"]["upgrades"]["shop_discount"]
      @reward_picks = $files.save_data["player"]["upgrades"]["reward_picks"]
    end
  end

  def begin_turn
    @my_turn = true
    @combat_stats.mod_max_focus =
      @combat_stats.max_focus - @combat_stats.statuses[$STATUS_TYPES["FROST"]]
    @combat_stats.mod_max_focus = 0 if @combat_stats.mod_max_focus < 0
    @combat_stats.focus = @combat_stats.mod_max_focus
    @combat_stats.calc_status(type: "RESTORATION")
    @combat_stats.calc_status(type: "FROST")
  end

  def tick
    @combat_stats.tick
  end

  # setter
  def my_turn=(value)
    @my_turn = value
  end

  # predicate reader
  def my_turn?
    @my_turn
  end

  def add_stun(num_turns)
    @stunned_turns += num_turns
  end
end
