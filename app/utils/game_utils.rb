# frozen_string_literal: true

module GameUtils
  def self.status_label(x, y, text, r, g, b, scale)
    $game.status_label(x, y, text, r, g, b, scale)
  end

  def self.craftable_ingredients?
    $iids.select { |_id, ing| !ing.base }
  end

  def self.is_potion(item_id)
    item_id.start_with?("p")
  end

  def self.gen_new_card(id = nil, is_reward: false)
    all_ids = $pids.keys + $iids.keys
    if id.nil?
      id = $iids.keys.sample
      id = $iids.keys.sample while id == "i001"
    end

    new_ent_id = get_rand_id
    $entity_ids << new_ent_id
    if is_reward
      name = $iids[id].name
      img = $iids[id].path
      IngredientRewardCard.new(id, new_ent_id, name, 0, img)
    elsif is_potion(id)
      PotionCard.new(
        id,
        new_ent_id,
        $pids[id].name,
        $pids[id].fc,
        $pids[id].path,
        $pids[id].max_uses,
        uses_left: $pids[id].max_uses
      )
    else
      IngredientCard.new(id, new_ent_id, $iids[id].name, 0, $iids[id].path)
    end
  end

  def self.get_rand_id
    new_id = Numeric.rand(1..50_000)
    new_id = Numeric.rand(1..50_000) while $entity_ids.include?(new_id)
    new_id
  end

  def self.new_id?
    new_ent_id = get_rand_id
    $entity_ids << new_ent_id
    new_ent_id
  end
end
