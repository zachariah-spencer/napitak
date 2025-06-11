# RecipeBook manages available recipes and crafting logic.
class RecipeBook
  attr_gtk
  attr :unlocked_recipes

  # Initialize with global recipe definitions and ingredient definitions.
  # potion_defs: hash mapping recipe_id to data, e.g.:
  #     "p001" => { name: "Rock Potion", ingredients: [["i001", 2], ["i002", 1]] }
  # ingredient_defs: hash mapping ingredient_id to ingredient metadata.
  def initialize(potion_defs = $pids, ingredient_defs = $iids)
    $recipe_book = self

    # @player = $player
    @potion_defs = potion_defs
    @ingredient_defs = ingredient_defs
    @unlocked_recipes = %w[p001 p002 p003 p004 i006 i007]

    all_recipe_ids
  end

  # List all known recipe IDs
  def all_recipe_ids
    @potion_defs.keys + craftable_ingredients?.keys
  end

  def all_craftables
    craftable_ingredients?.merge(@potion_defs)
  end

  # Check if a player has unlocked a given recipe
  # Assumes player has a Set or Array @unlocked_recipes of recipe IDs
  def unlocked?(recipe_id)
    @unlocked_recipes.include?(recipe_id)
  end

  # Check if player has sufficient ingredients in their inventory to craft recipe
  # Player should have an ingredient inventory with `deck` responding to `count`
  def can_craft?(recipe_id, ingredients_inventory: $player.ingredients.all_cards)
    return false unless unlocked?(recipe_id)
    required = all_craftables[recipe_id][:ingredients]

    required.all? do |ing_id, amt|
      ingredients_inventory.count { |card| card.id == ing_id } >= amt
    end
  end

  # Consume ingredients and produce a new PotionCard
  def craft(recipe_id, ingredients_inventory: $player.ingredients.all_cards)
    # check if recipe is unlocked and sufficient ingredients are possessed by player
    raise "Recipe not unlocked: #{recipe_id}" unless unlocked?(recipe_id)

    unless can_craft?(recipe_id, ingredients_inventory: ingredients_inventory)
      raise "Insufficient ingredients for #{recipe_id}"
    end

    # Remove required ingredients
    all_craftables[recipe_id][:ingredients].each do |ing_id, amt|
      amt.times do
        # find a card in inventory matching ing_id
        card = ingredients_inventory.find { |c| c.id == ing_id }
        $player.ingredients.remove(card)
      end
    end

    # Instantiate the potion card (assumes gen_new_card utility exists)
    card = gen_new_card(recipe_id)
    # Add to player's potion inventory

    if is_potion(card.id)
      $player.potions.add(card)
    else
      $player.ingredients.add(card)
    end

    card
  end

  def craftable_potion?(proposed_ingredients)
    # Extract the id's from all currently selected ingredient cards.
    selected_ids = proposed_ingredients.values.map &:id

    # Build a frequency hash of selected ingredient IDs.
    selected_counts = ingredient_counts(selected_ids)

    matching_potion = nil

    # Iterate through each potion definition in $pids.
    all_craftables.each do |potion_id, potion|
      # Build a frequency hash for the potion's ingredient list.
      required_counts = ingredient_counts(potion[:ingredients])

      # Check if the counts (and thus the ingredients including repeats) match exactly.
      if selected_counts == required_counts
        puts "Matching potion found: #{potion[:name]}"
        matching_potion = { id: potion_id, data: potion }
        break # Exit once a match is found, or remove break if you want to find all matches.
      end
    end

    unless matching_potion
      puts "No matching potion for selected ingredients: #{selected_ids}"
    end
    matching_potion
  end

  def ingredient_counts(ingredients)
    if ingredients.is_a?(Hash)
      # already id => count
      ingredients.dup
    else
      # array of ids
      ingredients.each_with_object(Hash.new(0)) { |id, h| h[id] += 1 }
    end
  end
end
