class MetaShop
  attr_gtk
  attr :sc_id

  def initialize()
    puts "init Meta Shop Screen"
    @sc_id = "meta_shop"

    @upgrades_price_sheet = {
      siz: {
        0 => { val: 5, amount: -1 },
        1 => { val: 6, amount: 100},
        2 => { val: 7, amount: 150},
        3 => { val: 8, amount: 300},
        4 => { val: 9, amount: 500},
        5 => { val: 10, amount: 1000},
      },

      max_foc: {
        0 => { val: 2, amount: -1 },
        1 => { val: 3, amount: 200},
        2 => { val: 4, amount: 400},
        3 => { val: 5, amount: 800},
      },

      max_hp: {
        0 => { val: 10, amount: -1 },
        1 => { val: 15, amount: 250},
        2 => { val: 20, amount: 500},
        3 => { val: 30, amount: 1000},
      },

      alc_tab_use: {
        0 => { val: 1, amount: -1 },
        1 => { val: 2, amount: 250},
        2 => { val: 3, amount: 500},
        3 => { val: 4, amount: 1000},
        4 => { val: 5, amount: 1500},
      },

      shop_disc: {
        0 => { val: 0, amount: -1 },
        1 => { val: 5, amount: 500},
        2 => { val: 10, amount: 1000},
        3 => { val: 20, amount: 1500},
        4 => { val: 30, amount: 2500},
        5 => { val: 50, amount: 5000},
      },

      picks: {
        0 => { val: 2, amount: -1 },
        1 => { val: 3, amount: 5000},
        2 => { val: 4, amount: 10000},
      },
    }

      @leave_btn = Button.new(
      x: GTK.args.grid.w - 25 - 150,
      y: 20,
      w: 150,
      h: 75,
      text: "Leave")

      @siz_btn = Button.new(
        x: 50,
        y: GTK.args.grid.h / 2,
        w: 150,
        h: 75,
        text: "Upgrade")


      @siz_levels = {
        val: $player.starting_inventory_size,
        level: @upgrades_price_sheet[:siz].find { |lvl, data| data[:val] == $player.starting_inventory_size }&.first,
        max_level: @upgrades_price_sheet[:siz].keys.size,
      }
  end


  def cleanup
    # $player.save_upgrades_data
  end

  def tick
    calc
  end

  def calc
    # GTK.request_quit if GTK.args.inputs.mouse.click and Geometry.intersect_rect?(GTK.args.inputs.mouse, quit_btn)
    # $game.new_run if GTK.args.inputs.mouse.click and Geometry.intersect_rect?(GTK.args.inputs.mouse, new_run_btn)
    $game.new_run if @leave_btn.clicked?
    

    @siz_btn.text = calc_price(@upgrades_price_sheet[:siz], @siz_levels)
  end

  def calc_price(price_sheet_entry, upgrade_levels)
    next_level_data = price_sheet_entry[upgrade_levels[:level] + 1]
    next_level_price = next_level_data[:amount]
    next_level_price
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

      anodyne_icon ||= {
        x: 100,
        y: GTK.args.grid.h - 75 - 40,
        w: 80,
        h: 80,
        path: "sprites/hexagon/violet.png",
        primitive_marker: :sprite
      }

      anodyne_amount ||= {
        x: 200,
        y: GTK.args.grid.h - 75,
        size_enum: 3,
        alignment_enum: 0,
        anchor_y: 0.5,
        text: "#{$player.anodyne}",
        r: 255,
        g: 180,
        b: 255,
        primitive_marker: :label
      }

      l1 << [top_panel, anodyne_icon, anodyne_amount]
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
        text: "Shop",
        primitive_marker: :label
      }

      l2 << [ encounter_label, @leave_btn.prefab, @siz_btn.prefab]
      return l2
    when 3
      l3 << [ ]
      return l3
    when 4
      l4 << [ ]
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end
end
