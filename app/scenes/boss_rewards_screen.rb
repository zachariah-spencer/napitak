# frozen_string_literal: true

class BossRewardsScreen < Scene
  attr :sc_id

  def initialize(boss_defeated_id: "dracolisk")
    puts "init BossRewardsScreen"
    @sc_id = "boss_rewards_screen"
    @boss_defeated_id = boss_defeated_id
    @reward_cards = []

    unlock_boss_rewards
  end

  def unlock_boss_rewards
    case @boss_defeated_id
    when "dracolisk"
      $recipe_book.unlock_base("i004")
      $recipe_book.unlock_base("i005")
      @reward_cards << RewardCard.new("i004")
      @reward_cards << RewardCard.new("i005")

    end
  end

  def cleanup
    puts "cleanup"
  end

  def tick
    calc_card_positions
    if GTK.args.inputs.mouse.click
      $game.change_scene(prev_sc: @sc_id, next_scene: "rewards_screen")
    end
  end

  def calc_card_positions
    @reward_cards.each_with_index do |c, i|
      c.f_pos.y = GTK.args.grid.h / 2 - 196
      c.calc_position @reward_cards.size, i
      c.tick
    end
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

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
      return l1
    when 2
      l2 << []
      return l2
    when 3
      l3 << []
      return l3
    when 4
      rewards_left_label = {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 + 128,
        alignment_enum: 1,
        size_px: Math.sin(Kernel.tick_count * 0.08) + 32,
        r: 255,
        g: 255,
        b: 255,
        text: "Congratulations, you've successfully recovered new base ingredients!",
        font: $FONT,
        primitive_marker: :label
      }

      @reward_cards.each do |c|
        l4 << c.prefab
      end
      l4 << [rewards_left_label]
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end
end
