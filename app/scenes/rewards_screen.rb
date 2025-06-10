class RewardsScreen
  attr_gtk
  attr :sc_id

  def initialize(choices: 4, picks: 2)
    puts "init RewardsScreen"
    @sc_id = "rewards_screen"
    @picks = picks
    @choices = {}
    choices.times.each do
      random_ingredient_id = $iids.keys().sample()
      random_ingredient_card =
        gen_new_card(random_ingredient_id, is_reward: true)
      @choices[random_ingredient_card.entity_id] = random_ingredient_card
    end
  end

  def cleanup
    puts "cleanup"
  end

  def tick
    calc_card_positions
    $player.hovered_cards = Geometry.find_all_intersect_rect inputs.mouse, get_card_rects

    if GTK.args.inputs.mouse.click
      clicked_card = Geometry.find_intersect_rect inputs.mouse, get_card_rects()
      if clicked_card
        puts "clicked on a card"
        clicked_card[:ref].use()
        @picks -= 1

        $game.change_scene(prev_sc: @sc_id, next_sc: "map") if @picks <= 0
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
    front_card = nil

    @choices.each do |id, c|
      prefab = c.prefab

      if c.grabbed
        front_card = prefab
      else
        cards.append prefab
      end
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
      l2 << [cards]
      return l2
    when 3
      l3 << [front_card]
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
        text: "Loot #{@picks} new ingredients!",
        primitive_marker: :label
      }
      l4 << [ rewards_left_label ]
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def calc_card_positions
    @choices.each_with_index do |(id, c), i| 
      c.calc_position @choices.length, i
      c.tick
    end
  end
end
