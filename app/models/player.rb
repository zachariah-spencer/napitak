class Player
  attr_gtk
  attr :ingredients, :potions, :focus, :max_focus, :hp, :max_hp, :stunned_turns, :hovered_cards, :died, :combat_stats

  def initialize
    $player = self

    @my_turn = true
    @combat_stats = CombatStatsComponent.new(hp: 20, focus: 4)
    @hp = 20
    @max_hp = 20
    @focus = 0
    @max_focus = 3
    @stunned_turns = 0
    @hovered_cards = []
    @died = false

    @ingredients = Inventory.new()
    @potions = Inventory.new()
  end

  def reset!
    @ingredients = Inventory.new()
    @potions = Inventory.new()
    @combat_stats.reset!
    save_inventory_data
    @died = false
    @my_turn = true
  end

  def save_inventory_data
    potions_save_data = []
    ingredients_save_data = []
    @potions.all_cards.each { |c| potions_save_data << c.save_data? }
    @ingredients.all_cards.each { |c| ingredients_save_data << c.save_data? }

    $files.save_data["player"]["potions"] = potions_save_data
    $files.save_data["player"]["ingredients"] = ingredients_save_data
  end

  def begin_turn
    @my_turn = true
    @combat_stats.mod_max_focus = @combat_stats.max_focus - @combat_stats.statuses[$STATUS_TYPES["FROST"]]
    @combat_stats.focus = @combat_stats.mod_max_focus
    @combat_stats.calc_status(type: "RESTORATION")
    @combat_stats.calc_status(type: "FROST")
  end

  def tick
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
