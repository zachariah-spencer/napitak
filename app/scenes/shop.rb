class Shop < Scene
  attr :sc_id

  def initialize()
    puts "init Shop Screen"
    @sc_id = "shop"
    $AUDIO_SERVICE.play_song(:shop_encounter)

    @leave_btn =
      Button.new(
        x: GTK.args.grid.w - 64 - 32,
        y: 64,
        w: 96,
        h: 48,
        text: "Leave"
      )

    @items = []
    10.times do 
      @items << ShopItemCard.new($SHOP_ITEMS.keys.sample)
    end

    spacing = 50

    num_per_row = @items.length / 2             # => 5
    row_width = (128 + spacing) * num_per_row - spacing  # 768px total
    start_x = (GTK.args.grid.w / 2) - (row_width / 2)
    start_x += 64    # 256px when grid.w = 1280
    @items.each_with_index do |item, i|
      if i < (@items.length / 2)
        # pos is center (anchor 0.5), so place at row center
        item.instant_set_position(x: item.pos.x, y: 512 - 64)
      else
        item.instant_set_position(x: item.pos.x, y: 256 - 64)
      end
      row_i = i
      if row_i >= 5
        row_i -= 5
      end

      x_pos = start_x + ((128 + spacing) * row_i)
      puts "INDEX: #{row_i}\nPOSITION SET RESULT X VAL: #{x_pos}"

      # pos is center; x_pos is already the center x
      item.instant_set_position(x: x_pos, y: item.pos.y)
    end
  end

  def cleanup
    super
    $player.save_feathers_data
    $player.save_run_upgrades_data
    $player.save_inventory_data
  end

  def tick
    @items.each { |item| item.tick }
    @leave_btn.tick
    @items.reject! { |item| item.bought_tick && item.bought_tick.elapsed_time >= 0.5.seconds}
    calc
  end

  def calc
    calc_mouse_inputs if !$game.input_locked
  end

  def calc_mouse_inputs
    @items.each do |item|
      if (clicked = item.pop_clicked)
        item.buy
      end
    end
    $game.change_scene(prev_sc: "shop", next_scene: "map") if @leave_btn.clicked?
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    case layer_num
    when 0

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

      l0 << [background]
      return l0
    when 1
      return l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 96,
        alignment_enum: 1,
        size_px: 64,
        r: 255,
        g: 255,
        b: 255,
        font: $FONT,
        text: "Trader",
        primitive_marker: :label
      }


      l2 << [encounter_label, @leave_btn.prefab]
      return l2
    when 3
      l3 << []
      return l3
    when 4
      cards = []
      @items.each do |item| 
        card, tooltip = item.prefab
        cards << card
      end
      l4 << cards
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end
end
