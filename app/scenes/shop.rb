class Shop < Scene
  attr :sc_id

  def initialize()
    puts "init Shop Screen"
    @sc_id = "shop"

    @leave_btn =
      Button.new(
        x: GTK.args.grid.w - 25 - 150,
        y: 20,
        w: 150,
        h: 75,
        text: "Leave"
      )

    @items = []
    10.times do 
      @items << ShopItemCard.new($SHOP_ITEMS.keys.sample)
    end

    spacing = 32
    start_x = (GTK.args.grid.w / 2) - ((128 + spacing) * (@items.length / 2))
    @items.each_with_index do |item, i|
      if i < (@items.length / 2)
        item.instant_set_position(x: item.pos.x, y: 512 - 128)
      else
        item.instant_set_position(x: item.pos.x, y: 256 - 128)
      end
      row_i = i
      if row_i >= 5
        row_i -= 5
      end

      x_pos = start_x + ((128 + spacing) * row_i)
      puts "INDEX: #{row_i}\nPOSITION SET RESULT X VAL: #{x_pos}"

      item.instant_set_position(x: x_pos, y: item.pos.y)
    end
  end

  def cleanup
    # $player.save_upgrades_data
  end

  def tick
    @items.each { |item| item.tick }
    calc
  end

  def calc
    calc_mouse_inputs if !$game.input_locked
  end

  def calc_mouse_inputs
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
      background ||= {
        x: 0,
        y: 0,
        w: GTK.args.grid.w,
        h: GTK.args.grid.h,
        r: 50,
        g: 50,
        b: 70,
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
        r: 100,
        g: 100,
        b: 110,
        a: 50,
        primitive_marker: :solid
      }

      feathers_icon ||= {
        x: 100,
        y: GTK.args.grid.h - 75 - 40,
        w: 80,
        h: 80,
        path: "sprites/hexagon/white.png",
        primitive_marker: :sprite
      }

      feathers_amount ||= {
        x: 200,
        y: GTK.args.grid.h - 75,
        size_enum: 3,
        alignment_enum: 0,
        anchor_y: 0.5,
        text: "#{$player.feathers}",
        r: 255,
        g: 180,
        b: 255,
        primitive_marker: :label
      }

      l1 << [top_panel, feathers_icon, feathers_amount]
      return l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 50,
        alignment_enum: 1,
        size_px: Math.sin(Kernel.tick_count * 0.08) * 4 + 40,
        r: 255,
        g: 255,
        b: 255,
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
