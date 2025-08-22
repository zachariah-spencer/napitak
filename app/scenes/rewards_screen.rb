# frozen_string_literal: true

class RewardsScreen < Scene
  attr :sc_id

  def initialize(choices: 4, picks: 2)
    puts "init RewardsScreen"
    @sc_id = "rewards_screen"
    @picks = picks
    @looting_ingredients = false
    @looting_upgrades = false
    @choosing_ended = false
    @alt_upgrades_label_alpha = 255
    @loot_label_alpha = 255
    @final_message_alpha = 0
    @loot_label_y = GTK.args.grid.h / 2 - 80
    @choices_y = GTK.args.grid.h / 2 - 256 - 64

    @upgrades = {}
    hp_upgrade_card = RewardCard.new("s001")
    focus_upgrade_card = RewardCard.new("s002")
    @upgrades[hp_upgrade_card.entity_id] = hp_upgrade_card
    @upgrades[focus_upgrade_card.entity_id] = focus_upgrade_card

    @choices = {}
    choices.times.each do
      random_reward_id =
        (
          $REWARD_ITEMS.keys.select do |id|
            $recipe_book.unlocked_bases.include?(id) # || id[0] == "s"
          end
        ).sample
      puts random_reward_id
      random_reward_card = RewardCard.new(random_reward_id)
      @choices[random_reward_card.entity_id] = random_reward_card
    end

    calc_cards_start_positions
  end

  def cleanup
    puts "cleanup"
  end

  def tick
    @alt_upgrades_label_alpha = @alt_upgrades_label_alpha.lerp(0, 0.08) if @looting_ingredients || @choosing_ended
    @loot_label_alpha = @loot_label_alpha.lerp(0, 0.08) if @looting_upgrades || @choosing_ended
    @final_message_alpha = @final_message_alpha.lerp( 255, 0.008) if @choosing_ended
    @loot_label_y = @loot_label_y.lerp(GTK.args.grid.h / 2 + 200, 0.05) if @looting_ingredients
    @choices_y = @choices_y.lerp(GTK.args.grid.h / 2 - 128, 0.05) if @looting_ingredients
    calc_card_positions
    if !$game.input_locked
      $player.hovered_cards =
        Geometry.find_all_intersect_rect inputs.mouse, get_card_rects

      if GTK.args.inputs.mouse.click
        clicked_card =
          Geometry.find_intersect_rect inputs.mouse, get_card_rects()
        if clicked_card
          puts "clicked on a card"
          clicked_card[:ref].use
          if clicked_card[:ref].id[0] != "s"
            puts "HERE"
            @picks -= 1
            @looting_ingredients = true
            @upgrades.each { |id,c| c.mark_for_removal }
          else
            @looting_upgrades = true
            @choices.each { |id,c| c.mark_for_removal }
            @picks = 0
          end

          if @picks <= 0
            @choosing_ended = true
            $AUDIO_SERVICE.stop_song
            $AUDIO_SERVICE.play_sound(:flee_fanfare)
            @choices.each { |id,c| c.mark_for_removal }
            @upgrades.each { |id,c| c.mark_for_removal }
            GTK.on_tick_count(Kernel.tick_count + 4.seconds) { leave }
            $game.input_locked = true
          end
        end
      end
    end

    
    calc_entity_removals()
  end

  def leave
    $game.change_scene(prev_sc: @sc_id, next_scene: "map")
  end

  def get_card_rects
    choices_with_refs = @choices.values.map do |card|
      r = card.rect.dup
      r[:ref] = card # attach the actual Card instance
      r
    end

    upgrades_with_refs = @upgrades.values.map do |card|
      r = card.rect.dup
      r[:ref] = card # attach the actual Card instance
      r
    end

    choices_with_refs + upgrades_with_refs
  end

  def calc_entity_removals
    @choices.reject! { |id, c| c.needs_removed }
    @upgrades.reject! { |id, c| c.needs_removed }
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    cards ||= []
    front_card = []

    @choices.merge(@upgrades).each do |id, c|
      c.grabbed ? front_card << c.prefab : cards << c.prefab
    end

    case layer_num
    when 0
      background_solid = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 0,
        g: 0,
        b: 0,
        primitive_marker: :solid
      }
      bg_tile_index = 0.frame_index(24, 1.0.seconds, true)
      background = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 50,
        g: 50,
        b: 50,
        a: 200,
        path:
          "sprites/background_frames/sketchybackground#{bg_tile_index + 1}.png"
      }

      l0 << [background_solid, background]
      #l0.flatten!
      return l0
    when 1
      #l1.flatten!
      return l1
    when 2
      l2 << [cards]
      #l2.flatten!
      return l2
    when 3
      l3 << front_card unless front_card.empty?
      #l3.flatten!
      return l3
    when 4
      rewards_left_label = {
        x: GTK.args.grid.w / 2,
        y: @loot_label_y,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 70,
        r: 255,
        g: 255,
        b: 255,
        a: @loot_label_alpha,
        text: "OR SELECT #{@looting_ingredients ? @picks : 2} NEW INGREDIENTS",
        font: $FONT,
        primitive_marker: :label
      }

      alt_upgrade_label = {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 100,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 70,
        r: 255,
        g: 255,
        b: 255,
        a: @alt_upgrades_label_alpha,
        text: "PICK AN UPGRADE",
        font: $FONT,
        primitive_marker: :label
      }

      final_message = {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2,
        anchor_x: 0.5,
        anchor_y: 0.5,
        size_px: 100,
        r: 255,
        g: 255,
        b: 255,
        a: @final_message_alpha,
        text: "NOW JOURNEY ONWARD...",
        font: $FONT,
        primitive_marker: :label
      }
      l4 << [rewards_left_label, alt_upgrade_label, final_message]
      #l4.flatten!
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def calc_cards_start_positions
    @upgrades.each_with_index do |(id, c), i|
      c.instant_calc_position @upgrades.length, i, GTK.args.grid.h / 2 + 12
    end

    @choices.each_with_index do |(id, c), i|
      c.instant_calc_position @choices.length, i, @choices_y
    end
  end

  def calc_card_positions
    @upgrades.each_with_index do |(id, c), i|
      c.f_pos.y = GTK.args.grid.h / 2 + 12
      c.calc_position @upgrades.length, i
      c.tick
    end

    @choices.each_with_index do |(id, c), i|
      c.f_pos.y = @choices_y
      c.calc_position @choices.length, i
      c.tick
    end
  end
end
