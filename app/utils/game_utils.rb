# frozen_string_literal: true

module GameUtils
  def self.status_label(x, y, text, r, g, b, scale)
    $game.status_label(x, y, text, r, g, b, scale)
  end

  def self.announce(text: "debug", duration: 1.0.seconds)
    $announcement_manager.add_announcement(Announcement.new(text: text, duration: duration))
  end

  def self.craftable_ingredients?
    $IIDS.select { |_id, ing| !ing.base }
  end

  def self.base_ingredients?
    $IIDS.select { |_id, ing| ing.base }
  end

  def self.is_potion(item_id)
    item_id.to_s.start_with?("p")
  end

  def self.gen_new_card(id = nil, is_reward: false)
    all_ids = $PIDS.keys + $IIDS.keys
    if id.nil?
      id = $IIDS.keys.sample
      id = $IIDS.keys.sample while id == "i001"
    end

    new_ent_id = get_rand_id
    $entity_ids << new_ent_id
    if is_reward
      name = $IIDS[id].name
      img = $IIDS[id].path
      IngredientRewardCard.new(id, new_ent_id, name, 0, img)
    elsif is_potion(id)
      PotionCard.new(
        id,
        new_ent_id,
        $PIDS[id].name,
        $PIDS[id].fc,
        $PIDS[id].path,
        $PIDS[id].max_uses,
        uses_left: $PIDS[id].max_uses
      )
    else
      IngredientCard.new(id, new_ent_id, $IIDS[id].name, 0, $IIDS[id].path)
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
