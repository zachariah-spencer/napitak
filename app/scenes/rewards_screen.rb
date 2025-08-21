# frozen_string_literal: true

class RewardsScreen < Scene
  attr :sc_id

  def initialize(choices: 4, picks: 2)
    puts "init RewardsScreen"
    @sc_id = "rewards_screen"
    @picks = picks
    @choices = {}
    choices.times.each do
      random_reward_id =
        (
          $REWARD_ITEMS.keys.select do |id|
            $recipe_book.unlocked_bases.include?(id) || id[0] == "s"
          end
        ).sample
      puts random_reward_id
      random_reward_card = RewardCard.new(random_reward_id)
      @choices[random_reward_card.entity_id] = random_reward_card
    end
  end

  def cleanup
    puts "cleanup"
  end

  def tick
    calc_card_positions
    if !$game.input_locked
      $player.hovered_cards =
        Geometry.find_all_intersect_rect inputs.mouse, get_card_rects

      if GTK.args.inputs.mouse.click
        clicked_card =
          Geometry.find_intersect_rect inputs.mouse, get_card_rects()
        if clicked_card
          puts "clicked on a card"
          clicked_card[:ref].use()
          @picks -= 1

          $game.change_scene(prev_sc: @sc_id, next_scene: "map") if @picks <= 0
        end
      end
    end

    calc_entity_removals()
  end

  def get_card_rects
    @choices.values.map do |card|
      r = card.rect.dup
      r[:ref] = card # attach the actual Card instance
      r
    end
  end

  def calc_entity_removals
    @choices.reject! { |id, c| c.needs_removed }
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    cards ||= []
    front_card = []

    @choices.each do |id, c|
      c.grabbed ? front_card << c.prefab : cards << c.prefab
    end

    case layer_num
    when 0
      background ||= {
        x: 0,
        y: 0,
        w: GTK.args.grid.w,
        h: GTK.args.grid.h,
        r: 10,
        g: 10,
        b: 20,
        primitive_marker: :solid
      }

      l0 << [background]
      #l0.flatten!
      return l0
    when 1
      top_panel ||= {
        x: 0,
        y: GTK.args.grid.h - 150,
        w: GTK.args.grid.w,
        h: 150,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid
      }

      l1 << [top_panel]
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
        y: 100,
        alignment_enum: 1,
        size_px: Math.sin(Kernel.tick_count * 0.08) * 4 + 80,
        r: 255,
        g: 255,
        b: 255,
        text: "Loot #{@picks}!",
        primitive_marker: :label
      }
      l4 << [rewards_left_label]
      #l4.flatten!
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def calc_card_positions
    @choices.each_with_index do |(id, c), i|
      c.f_pos.y = GTK.args.grid.h / 2 - 80
      c.calc_position @choices.length, i
      c.tick
    end
  end
end
