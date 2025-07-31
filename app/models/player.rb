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
       :start_maximum_focus,
       :start_maximum_hp,
       :alchemy_table_uses,
       :shop_discount,
       :reward_picks,
       :prev_loadout_ingredients,
       :prev_loadout_potions,
       :feathers

  def initialize
    $player = self

    # meta-progression upgrades and currency vars
    @anodyne = 0
    @starting_inventory_size = 5
    @maximum_focus = 2
    @maximum_hp = 10
    @start_maximum_hp = 10
    @start_maximum_focus = 2
    @alchemy_table_uses = 1
    @shop_discount = 0 # out of 100 (integer percentile) (CURRENTLY UNUSED)
    @reward_picks = 2

    @my_turn = true
    @combat_stats = CombatStatsComponent.new(hp: 20, focus: 4, x: 64, y: 262, columns: 2)
    @stunned_turns = 0
    @hovered_cards = []
    @died = false
    @feathers = load_feathers_data || 0
    save_feathers_data

    @ingredients = Inventory.new()
    @potions = Inventory.new()
    @prev_loadout_ingredients = Inventory.new()
    @prev_loadout_potions = Inventory.new()

    $event_bus.subscribe(:player_hurt, self) do |data|
      @combat_stats.hurt(data[:amount], data[:type])
    end
    $event_bus.subscribe(:player_heal, self) do |amt|
      @combat_stats.heal(amt)
    end
    $event_bus.subscribe(:player_apply_status, self) do |data|
      @combat_stats.apply_status(type: data[:type], stacks: data[:stacks])
    end
  end

  def reset!
    @ingredients = Inventory.new()
    @potions = Inventory.new()
    @maximum_hp = @start_maximum_hp
    @maximum_focus = @start_maximum_focus
    @combat_stats.reset!(@maximum_hp, @maximum_focus)
    @died = false
    @my_turn = true
    @feathers = 0

    save_feathers_data
    save_upgrades_data
    save_run_upgrades_data
    save_inventory_data
  end

  def save_inventory_data
    potions_save_data, ingredients_save_data = get_inventory_save_data
    $files.save_data["player"]["potions"] = potions_save_data
    $files.save_data["player"]["ingredients"] = ingredients_save_data
  end

  def save_feathers_data
    $files.save_data["player"]["feathers"] = @feathers
  end

  def load_feathers_data
    if $files.save_data["player"]["feathers"]
      return @feathers = $files.save_data["player"]["feathers"] 
    else
      return nil
    end
  end

  def save_run_upgrades_data
    $files.save_data["player"]["run_upgrades"]["maximum_focus"] = @maximum_focus
    $files.save_data["player"]["run_upgrades"]["maximum_hp"] = @maximum_hp
  end

  def load_run_upgrades_data
    @maximum_focus = $files.save_data["player"]["run_upgrades"]["maximum_focus"]
    @maximum_hp = $files.save_data["player"]["run_upgrades"]["maximum_hp"]
  end

  def get_inventory_save_data
    potions_save_data = []
    ingredients_save_data = []
    @potions.all_cards.each { |c| potions_save_data << c.save_data? }
    @ingredients.all_cards.each { |c| ingredients_save_data << c.save_data? }

    return potions_save_data, ingredients_save_data
  end

  def save_prev_loadout_save_data
  end

  def load_prev_loadout_save_data
    pots = Inventory.new()
    ings = Inventory.new()
    if $files.save_data["player"]["previous_starting_potions_config"]
      $files.save_data["player"][
        "previous_starting_potions_config"
      ].each do |data|
        id = data["id"]
        puts "ID FROM SAVE: #{id}"
        uses = data["uses_left"].to_i
        pots.add(
          PotionCard.new(
            id,
            GameUtils.new_id?,
            $PIDS[id].name,
            $PIDS[id].fc,
            $PIDS[id].path,
            $PIDS[id].max_uses,
            uses_left: uses
          )
        )
      end
    end

    if $files.save_data["player"]["previous_starting_ingredients_config"]
      $files.save_data["player"][
        "previous_starting_ingredients_config"
      ].each do |id|
        ings.add(
          IngredientCard.new(
            id,
            GameUtils.new_id?,
            $IIDS[id].name,
            -1,
            $IIDS[id].path
          )
        )
      end
    end

    @prev_loadout_potions = pots
    @prev_loadout_ingredients = ings

    return pots, ings
  end

  def save_upgrades_data
    $files.save_data["player"]["upgrades"]["anodyne"] = @anodyne
    $files.save_data["player"]["upgrades"][
      "starting_inventory_size"
    ] = @starting_inventory_size
    $files.save_data["player"]["upgrades"]["start_maximum_focus"] = @start_maximum_focus
    $files.save_data["player"]["upgrades"]["start_maximum_hp"] = @start_maximum_hp
    $files.save_data["player"]["upgrades"][
      "alchemy_table_uses"
    ] = @alchemy_table_uses
    $files.save_data["player"]["upgrades"]["shop_discount"] = @shop_discount
    $files.save_data["player"]["upgrades"]["reward_picks"] = @reward_picks
  end

  def load_inventory_data
    if $files.save_data["player"]["potions"]
      $files.save_data["player"]["potions"].each do |data|
        id = data["id"]
        uses = data["uses_left"].to_i
        @potions.add(
          PotionCard.new(
            id,
            GameUtils.new_id?,
            $PIDS[id].name,
            $PIDS[id].fc,
            $PIDS[id].path,
            $PIDS[id].max_uses,
            uses_left: uses
          )
        )
      end
    end

    if $files.save_data["player"]["ingredients"]
      $files.save_data["player"]["ingredients"].each do |id|
        @ingredients.add(
          IngredientCard.new(
            id,
            GameUtils.new_id?,
            $IIDS[id].name,
            -1,
            $IIDS[id].path
          )
        )
      end
    end

    if $files.save_data["player"]["previous_run_ingredients"]
      $files.save_data["player"]["previous_run_ingredients"].each do |id|
        @prev_loadout_ingredients.add(
          IngredientCard.new(
            id,
            GameUtils.new_id?,
            $IIDS[id].name,
            -1,
            $IIDS[id].path
          )
        )
      end
    end

    if $files.save_data["player"]["previous_run_potions"]
      $files.save_data["player"]["previous_run_potions"].each do |data|
        id = data["id"]
        uses = data["uses_left"].to_i
        @prev_loadout_potions.add(
          PotionCard.new(
            id,
            GameUtils.new_id?,
            $PIDS[id].name,
            $PIDS[id].fc,
            $PIDS[id].path,
            $PIDS[id].max_uses,
            uses_left: uses
          )
        )
      end
    end
  end

  def load_upgrades_data
    # Always saved and loaded as a group so if "starting_inventory_size" exists then a save file exists as well.
    if $files.save_data["player"]["upgrades"]["anodyne"]
      @anodyne = $files.save_data["player"]["upgrades"]["anodyne"]
      @starting_inventory_size =
        $files.save_data["player"]["upgrades"]["starting_inventory_size"]
      @start_maximum_focus = $files.save_data["player"]["upgrades"]["start_maximum_focus"]
      @start_maximum_hp = $files.save_data["player"]["upgrades"]["start_maximum_hp"]
      @alchemy_table_uses =
        $files.save_data["player"]["upgrades"]["alchemy_table_uses"]
      @shop_discount = $files.save_data["player"]["upgrades"]["shop_discount"]
      @reward_picks = $files.save_data["player"]["upgrades"]["reward_picks"]
    end
  end

  def begin_turn
    @my_turn = true
    @combat_stats.mod_max_focus =
      @combat_stats.max_focus - @combat_stats.statuses[$STATUS_TYPES[:FROST]]
    @combat_stats.mod_max_focus = 0 if @combat_stats.mod_max_focus < 0
    @combat_stats.focus = @combat_stats.mod_max_focus
    @combat_stats.calc_status(type: :RESTORATION)
    @combat_stats.calc_status(type: :FROST)
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
