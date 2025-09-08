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
       :feathers,
       :status_effects,
       :potion_animations,
       :hp_shards,
       :focus_shards,
       :previous_enemy_feathers_value

  def initialize
    $player = self

    # meta-progression upgrades and currency vars
    @anodyne = 0
    @maximum_focus = 4
    @maximum_hp = 100
    @starting_inventory_size = 5
    @start_maximum_hp = 100
    @hp_shards = 0
    @focus_shards = 0
    @start_maximum_focus = 4
    @alchemy_table_uses = 2
    @shop_discount = 0 # out of 100 (integer percentile) (CURRENTLY UNUSED)
    @reward_picks = 2
    @accuracy = 100.0

    @my_turn = true
    @combat_stats =
      CombatStatsComponent.new(
        hp: 100,
        focus: 4,
        x: GTK.args.grid.w / 2,
        y: 256,
        ward_label_x: GTK.args.grid.w / 2 - 95,
        ward_label_y: GTK.args.grid.h - 60,
        stacks_x: 150,
        stacks_y: 158,
        columns: 2,
        parent: self
      )
    @potion_animations =
      PotionAnimationComponent.new(
        x: GTK.args.grid.w / 2 - 150,
        y: 0,
        w: 256,
        h: 720,
        tx: 256,
        ty: 0,
        tw: 256,
        th: 720
      )
    @status_effects = load_status_effects_data || []
    @stunned_turns = 0
    @hovered_cards = []
    @died = false
    @feathers = load_feathers_data || 0
    @previous_enemy_feathers_value = 0
    save_feathers_data

    @ingredients = Inventory.new()
    @potions = Inventory.new()
    @prev_loadout_ingredients = Inventory.new()
    @prev_loadout_potions = Inventory.new()

    $EVENT_BUS.subscribe(:player_hurt, self) do |data|
      @combat_stats.hurt(data[:amount], data[:type])
    end
    $EVENT_BUS.subscribe(:player_heal, self) { |amt| @combat_stats.heal(amt) }
    $EVENT_BUS.subscribe(:player_apply_status, self) do |data|
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
    @previous_enemy_feathers_value = 0
    @status_effects = []
    @hp_shards = 0
    @focus_shards = 0

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

  def save_status_effects_data
    $files.save_data["player"]["status_effects"].clear
    @status_effects.each do |effect|
      $files.save_data["player"]["status_effects"] << effect.save_data?
    end
  end

  def load_status_effects_data
    effects = []
    $files.save_data["player"]["status_effects"].each do |effect|
      effects << StatusEffect.new(
        effect: effect["effect"],
        value: effect["value"],
        duration: effect["duration"],
        encounters_since_started: effect["encounters_since_started"]
      )
    end
    puts effects
    effects
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
    $files.save_data["player"]["run_upgrades"]["hp_shards"] = @hp_shards
    $files.save_data["player"]["run_upgrades"]["focus_shards"] = @focus_shards
  end

  def inc_hp_shards
    @hp_shards = (@hp_shards || 0) + 1
    save_run_upgrades_data
    return unless @hp_shards >= 3

    @hp_shards = 0
    @maximum_hp += 5
    save_run_upgrades_data
  end

  def reward_feathers(amt)
    @feathers += amt
    @previous_enemy_feathers_value = amt
    save_feathers_data
  end

  def inc_focus_shards
    @focus_shards = (@focus_shards || 0) + 1
    save_run_upgrades_data
    return unless @focus_shards >= 3

    @focus_shards = 0
    @maximum_focus += 1
    save_run_upgrades_data
  end

  def load_run_upgrades_data
    run = $files.save_data["player"]["run_upgrades"] || {}
    # Fallback to current values if not present (handles older saves)
    @maximum_focus = run["maximum_focus"] || @maximum_focus
    @maximum_hp = run["maximum_hp"] || @maximum_hp
    @hp_shards = run.key?("hp_shards") ? run["hp_shards"] : 0
    @focus_shards = run.key?("focus_shards") ? run["focus_shards"] : 0
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
    $files.save_data["player"]["upgrades"][
      "start_maximum_focus"
    ] = @start_maximum_focus
    $files.save_data["player"]["upgrades"][
      "start_maximum_hp"
    ] = @start_maximum_hp
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
            uses_left: $PIDS[id].max_uses
          )
        )
      end
    end
  end

  def modified_accuracy?
    puts "ACCURACY: #{@accuracy}\n ACCURACY_MODIFIER: #{@combat_stats.accuracy_mod}\nFINAL_CALC: #{@accuracy + @combat_stats.accuracy_mod}\n"
    @accuracy + @combat_stats.accuracy_mod
  end

  def check_hit?
    hit_roll = Numeric.rand(0.0..100.0)
    if hit_roll <= modified_accuracy?
      true
    else
      $EVENT_BUS.publish(:attack_missed)
      GameUtils.status_label(
        GTK.args.grid.w / 2,
        GTK.args.grid.h - 500,
        "MISSED",
        255,
        255,
        255,
        64
      )
      false
    end
  end

  def load_upgrades_data
    # Always saved and loaded as a group so if "starting_inventory_size" exists then a save file exists as well.
    if $files.save_data["player"]["upgrades"]["anodyne"]
      @anodyne = $files.save_data["player"]["upgrades"]["anodyne"]
      @starting_inventory_size =
        $files.save_data["player"]["upgrades"]["starting_inventory_size"]
      @start_maximum_focus =
        $files.save_data["player"]["upgrades"]["start_maximum_focus"]
      @start_maximum_hp =
        $files.save_data["player"]["upgrades"]["start_maximum_hp"]
      @alchemy_table_uses =
        $files.save_data["player"]["upgrades"]["alchemy_table_uses"]
      @shop_discount = $files.save_data["player"]["upgrades"]["shop_discount"]
      @reward_picks = $files.save_data["player"]["upgrades"]["reward_picks"]
    end
  end

  def begin_turn
    @my_turn = true
    @combat_stats.mod_max_focus =
      @combat_stats.max_focus + @combat_stats.consume_bonus_focus -
        @combat_stats.statuses[$STATUS_TYPES[:FROST]]
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

  def prefab
    @potion_animations.prefab
  end
end
