# frozen_string_literal: true

module GameUtils

  def self.sparkle_particle(x:,y:,r:,g:,b:)
    $game.sparkle_particle(x: x,y: y,r: r,g: g,b: b)
  end

  def self.status_label(x, y, text, r, g, b, scale)
    $game.status_label(x, y, text, r, g, b, scale)
  end

  def self.announce(text: "debug", duration: 1.0.seconds, x: Grid.w / 2 - 200, y: Grid.h - 125 - 50, tutorial_id: -1)
    $announcement_manager.add_announcement(
      Announcement.new(text: text, duration: duration, x: x, y: y, large: false, tutorial_id: tutorial_id)
    )
  end

  def self.announce_lg(text: "debug", duration: 1.0.seconds, x: Grid.w / 2 - 400, y: Grid.h - 250 - 50, tutorial_id: -1)
    $announcement_manager.add_announcement(
      Announcement.new(text: text, duration: duration, x: x, y: y, large: true, tutorial_id: tutorial_id)
    )
  end

  def self.current_announcement_completed?
    $announcement_manager.completed_announcement
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

  def self.tutorial_string?(i)
    tutorial_json = GTK.read_file("data/tutorials.json")
    return {} unless tutorial_json # Return empty hash if file doesn't exist
    text = GTK.parse_json(tutorial_json)[i.to_s]
    [i, text]
  end

  def self.camera_shake(intensity: 8.0, duration: 0.3.seconds, include_ui: false)
    $game.camera_shake(intensity: intensity, duration: duration, include_ui: include_ui)
  end
end
