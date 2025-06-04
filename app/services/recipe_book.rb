# RecipeBook manages available recipes and crafting logic.
class RecipeBook
  attr_gtk
  attr

  # Initialize with global recipe definitions and ingredient definitions.
  # potion_defs: hash mapping recipe_id to data, e.g.:
  #     "p001" => { name: "Rock Potion", ingredients: [["i001", 2], ["i002", 1]] }
  # ingredient_defs: hash mapping ingredient_id to ingredient metadata.
  def initialize(potion_defs = $pids, ingredient_defs = $iids)
    $recipe_book = self

    # @player = $player
    @potion_defs = potion_defs
    @ingredient_defs = ingredient_defs
    @unlocked_recipes = %w[p001 p002 p003 p004]
  end

  # List all known recipe IDs
  def all_recipe_ids
    @potion_defs.keys
  end

  # Check if a player has unlocked a given recipe
  # Assumes player has a Set or Array @unlocked_recipes of recipe IDs
  def unlocked?(recipe_id)
    @unlocked_recipes.include?(recipe_id)
  end

  # Check if player has sufficient ingredients in their inventory to craft recipe
  # Player should have an ingredient inventory with `deck` responding to `count`
  def can_craft?(recipe_id)
    return false unless unlocked?(recipe_id)
    required = @potion_defs[recipe_id][:ingredients]

    required.all? do |ing_id, amt|
      $player.ingredients.all_cards.count { |card| card.id == ing_id } >= amt
    end
  end

  # Consume ingredients and produce a new PotionCard
  def craft(recipe_id)
    # check if recipe is unlocked and sufficient ingredients are possessed by player
    raise "Recipe not unlocked: #{recipe_id}" unless unlocked?(recipe_id)

    unless can_craft?(recipe_id)
      raise "Insufficient ingredients for #{recipe_id}"
    end

    # Remove required ingredients
    @potion_defs[recipe_id][:ingredients].each do |ing_id, amt|
      amt.times do
        #FIXME: REMOVE INGREDIENTS FROM ALL INVENTORY SOURCES AND
        # find a card in inventory matching ing_id
        card = $player.ingredients.deck.draw_pile.find { |c| c.id == ing_id }
        $player.ingredients.remove(card)
      end
    end

    # Instantiate the potion card (assumes gen_new_card utility exists)
    potion_card = gen_new_card(recipe_id)
    # Add to player's potion inventory
    $player.potions.add(potion_card)
    potion_card
  end

  def craftable_potion?(proposed_ingredients)
    # Extract the id's from all currently selected ingredient cards.
    selected_ids = proposed_ingredients.values.map &:id

    # Build a frequency hash of selected ingredient IDs.
    selected_counts = ingredient_counts(selected_ids)

    matching_potion = nil

    # Iterate through each potion definition in $pids.
    $pids.each do |potion_id, potion|
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
