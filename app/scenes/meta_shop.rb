class MetaShop < Scene
  attr :sc_id

  def initialize()
    puts "init Meta Shop Screen"
    @sc_id = "meta_shop"
    @upgrades_price_sheet = price_sheet?

    @leave_btn =
      Button.new(
        x: GTK.args.grid.w - 25 - 150,
        y: 20,
        w: 150,
        h: 75,
        text: "Leave"
      )

    
    @siz_info = {
      sym: :siz,
      level:
        @upgrades_price_sheet[:siz]
          .find { |lvl, data| data[:val] == $player.starting_inventory_size }
          &.first,
      max_level: @upgrades_price_sheet[:siz].keys.size - 1,
      val: $player.starting_inventory_size
    }
    @siz_btn =
      Button.new(x: 100, y: GTK.args.grid.h / 2 + 50, w: 180, h: 100, text: "#{calc_price(@upgrades_price_sheet[:siz], @siz_info)}")
    @siz_level_bar = UpgradeLevelBarWidget.new(x: 100, y: GTK.args.grid.h / 2, w: 180, h: 50, levels: @siz_info[:max_level], level: @siz_info[:level])
    @siz_info[:widget] = @siz_level_bar 

    @max_hp_info = {
      sym: :max_hp,
      level:
        @upgrades_price_sheet[:max_hp]
          .find { |lvl, data| data[:val] == $player.start_maximum_hp }
          &.first,
      max_level: @upgrades_price_sheet[:max_hp].keys.size - 1,
      val: $player.start_maximum_hp
    }
    @max_hp_btn =
      Button.new(x: GTK.args.grid.w / 2 - 90, y: GTK.args.grid.h / 2 + 50, w: 180, h: 100, text: "#{calc_price(@upgrades_price_sheet[:max_hp], @max_hp_info)}")
    @max_hp_level_bar = UpgradeLevelBarWidget.new(x: GTK.args.grid.w / 2 - 90, y: GTK.args.grid.h / 2, w: 180, h: 50, levels: @max_hp_info[:max_level], level: @max_hp_info[:level])
    @max_hp_info[:widget] = @max_hp_level_bar

    
    @max_focus_info = {
      sym: :max_foc,
      level:
        @upgrades_price_sheet[:max_foc]
          .find { |lvl, data| data[:val] == $player.start_maximum_focus }
          &.first,
      max_level: @upgrades_price_sheet[:max_foc].keys.size - 1,
      val: $player.start_maximum_focus
    }
    @max_focus_btn =
      Button.new(x: GTK.args.grid.w - 90 - 200, y: GTK.args.grid.h / 2 + 50, w: 180, h: 100, text: "#{calc_price(@upgrades_price_sheet[:max_foc], @max_focus_info)}")
    @max_focus_level_bar = UpgradeLevelBarWidget.new(x: GTK.args.grid.w - 90 - 200, y: GTK.args.grid.h / 2, w: 180, h: 50, levels: @max_focus_info[:max_level], level: @max_focus_info[:level])
    @max_focus_info[:widget] = @max_focus_level_bar

    
    @alc_tab_use_info = {
      sym: :alc_tab_use,
      level:
        @upgrades_price_sheet[:alc_tab_use]
          .find { |lvl, data| data[:val] == $player.alchemy_table_uses }
          &.first,
      max_level: @upgrades_price_sheet[:alc_tab_use].keys.size - 1,
      val: $player.alchemy_table_uses
    }
    @alc_tab_use_btn =
      Button.new(x: 100, y: GTK.args.grid.h / 2 - 180, w: 180, h: 100, text: "#{calc_price(@upgrades_price_sheet[:alc_tab_use], @alc_tab_use_info)}")
    @alc_tab_use_level_bar = UpgradeLevelBarWidget.new(x: 100, y: GTK.args.grid.h / 2 - 180 - 50, w: 180, h: 50, levels: @alc_tab_use_info[:max_level], level: @alc_tab_use_info[:level])
    @alc_tab_use_info[:widget] = @alc_tab_use_level_bar

    
    @shop_disc_info = {
      sym: :shop_disc,
      level:
        @upgrades_price_sheet[:shop_disc]
          .find { |lvl, data| data[:val] == $player.shop_discount }
          &.first,
      max_level: @upgrades_price_sheet[:shop_disc].keys.size - 1,
      val: $player.shop_discount
    }
    @shop_disc_btn =
      Button.new(x: GTK.args.grid.w / 2 - 90, y: GTK.args.grid.h / 2 - 180, w: 180, h: 100, text: "#{calc_price(@upgrades_price_sheet[:shop_disc], @shop_disc_info)}")
    @shop_disc_level_bar = UpgradeLevelBarWidget.new(x: GTK.args.grid.w / 2 - 90, y: GTK.args.grid.h / 2 - 180 - 50, w: 180, h: 50, levels: @shop_disc_info[:max_level], level: @shop_disc_info[:level])
    @shop_disc_info[:widget] = @shop_disc_level_bar
  
    
    @picks_info = {
      sym: :picks,
      level:
        @upgrades_price_sheet[:picks]
          .find { |lvl, data| data[:val] == $player.reward_picks }
          &.first,
      max_level: @upgrades_price_sheet[:picks].keys.size - 1,
      val: $player.reward_picks
    }
    @picks_btn =
      Button.new(x: GTK.args.grid.w - 90 - 200, y: GTK.args.grid.h / 2 - 180, w: 180, h: 100, text: "#{calc_price(@upgrades_price_sheet[:picks], @picks_info)}")
    @picks_level_bar = UpgradeLevelBarWidget.new(x: GTK.args.grid.w - 90 - 200, y: GTK.args.grid.h / 2 - 180 - 50, w: 180, h: 50, levels: @picks_info[:max_level], level: @picks_info[:level])
    @picks_info[:widget] = @picks_level_bar
  end

  def cleanup
    # $player.save_upgrades_data
  end

  def tick
    calc

    @siz_level_bar.tick
    @max_hp_level_bar.tick
    @max_focus_level_bar.tick
    @alc_tab_use_level_bar.tick
    @shop_disc_level_bar.tick
    @picks_level_bar.tick
  end

  def calc
    @siz_btn.text = calc_price(@upgrades_price_sheet[:siz], @siz_info)
    @max_hp_btn.text = calc_price(@upgrades_price_sheet[:max_hp], @max_hp_info)
    @max_focus_btn.text = calc_price(@upgrades_price_sheet[:max_foc], @max_focus_info)
    @alc_tab_use_btn.text = calc_price(@upgrades_price_sheet[:alc_tab_use], @alc_tab_use_info)
    @shop_disc_btn.text = calc_price(@upgrades_price_sheet[:shop_disc], @shop_disc_info)
    @picks_btn.text = calc_price(@upgrades_price_sheet[:picks], @picks_info)

    calc_mouse_inputs if !$game.input_locked
  end

  def calc_mouse_inputs
    $game.change_scene(prev_sc: "meta_shop", next_scene: "run_summary") if @leave_btn.clicked?
    buy_upgrade(@siz_info) if @siz_btn.clicked?
    buy_upgrade(@max_hp_info) if @max_hp_btn.clicked?
    buy_upgrade(@max_focus_info) if @max_focus_btn.clicked?
    buy_upgrade(@alc_tab_use_info) if @alc_tab_use_btn.clicked?
    buy_upgrade(@shop_disc_info) if @shop_disc_btn.clicked?
    buy_upgrade(@picks_info) if @picks_btn.clicked?
  end

  def calc_price(price_sheet_entry, upgrade_info)
    if can_buy?(upgrade_info)
      next_level_data = price_sheet_entry[upgrade_info[:level] + 1]
      next_level_data[:amount]
    else
      "MAX"
    end
  end

  def buy_upgrade(upgrade_info)
    price_sheet_entry = @upgrades_price_sheet[upgrade_info[:sym]]

    # check that upgrade level isn't at max level
    if can_buy?(upgrade_info) && player_has_enough_money?(upgrade_info)
      # deduct price from player currency
      $player.anodyne -= calc_price(@upgrades_price_sheet[upgrade_info[:sym]], upgrade_info)

      # increment upgrade level
      upgrade_info[:level] += 1

      # set upgrade value
      case upgrade_info[:sym]
      when :siz
        $player.starting_inventory_size = price_sheet_entry[upgrade_info[:level]][:val]
      when :max_hp
        $player.start_maximum_hp = price_sheet_entry[upgrade_info[:level]][:val]
      when :max_foc
        $player.start_maximum_focus = price_sheet_entry[upgrade_info[:level]][:val]
      when :alc_tab_use
        $player.alchemy_table_uses = price_sheet_entry[upgrade_info[:level]][:val]
      when :shop_disc
        $player.shop_discount = price_sheet_entry[upgrade_info[:level]][:val]
      when :picks
        $player.reward_picks = price_sheet_entry[upgrade_info[:level]][:val]
      end

      upgrade_info[:val] = price_sheet_entry[upgrade_info[:level]][:val]
      upgrade_info[:widget].change_level(upgrade_info[:level])
      $player.save_upgrades_data
    end

  end

  def player_has_enough_money?(upgrade_info)
    $player.anodyne >= calc_price(@upgrades_price_sheet[upgrade_info[:sym]], upgrade_info)
  end

  def can_buy?(upgrade_info)
    upgrade_info[:level] < upgrade_info[:max_level]
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

      siz_upgrade_label ||= {
        x: 200,
        y: GTK.args.grid.h / 2 + 190,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "Starting Ingredient Pouch Size",
        primitive_marker: :label
      }

      max_hp_upgrade_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 + 190,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "Maximum Starting HP",
        primitive_marker: :label
      }

      max_focus_upgrade_label ||= {
        x: GTK.args.grid.w - 200,
        y: GTK.args.grid.h / 2 + 190,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "Maximum Starting Focus",
        primitive_marker: :label
      }

      alc_tab_use_upgrade_label ||= {
        x: 200,
        y: GTK.args.grid.h / 2 - 40,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "Alchemy Workbench Uses",
        primitive_marker: :label
      }

      shop_disc_upgrade_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 - 40,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "Shop Discount %",
        primitive_marker: :label
      }

      picks_upgrade_label ||= {
        x: GTK.args.grid.w - 200,
        y: GTK.args.grid.h / 2 - 40,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "Combat Reward Choices",
        primitive_marker: :label
      }


      l2 << [encounter_label, @leave_btn.prefab, @siz_btn.prefab, siz_upgrade_label, @max_hp_btn.prefab, max_hp_upgrade_label, @max_focus_btn.prefab, max_focus_upgrade_label]
      l2 << [@alc_tab_use_btn.prefab, alc_tab_use_upgrade_label, @shop_disc_btn.prefab, shop_disc_upgrade_label, @picks_btn.prefab, picks_upgrade_label]
      return l2
    when 3
      siz_upgrade_val = {
        x: 190,
        y: GTK.args.grid.h / 2 + 35,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@siz_info[:val]}",
        primitive_marker: :label
      }

      max_hp_upgrade_val = {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 + 35,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@max_hp_info[:val]}",
        primitive_marker: :label
      }

      max_focus_upgrade_val = {
        x: GTK.args.grid.w - 200,
        y: GTK.args.grid.h / 2 + 35,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@max_focus_info[:val]}",
        primitive_marker: :label
      }

      alc_tab_use_upgrade_val = {
        x: 190,
        y: GTK.args.grid.h / 2 - 195,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@alc_tab_use_info[:val]}",
        primitive_marker: :label
      }

      shop_disc_upgrade_val = {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 - 195,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@shop_disc_info[:val]}",
        primitive_marker: :label
      }

      picks_upgrade_val = {
        x: GTK.args.grid.w - 200,
        y: GTK.args.grid.h / 2 - 195,
        alignment_enum: 1,
        size_enum: 2,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@picks_info[:val]}",
        primitive_marker: :label
      }
      l3 << [ @siz_level_bar.prefab, siz_upgrade_val, @max_hp_level_bar.prefab, max_hp_upgrade_val, @max_focus_level_bar.prefab, max_focus_upgrade_val]
      l3 << [ @alc_tab_use_level_bar.prefab, alc_tab_use_upgrade_val, @shop_disc_level_bar.prefab, shop_disc_upgrade_val, @picks_level_bar.prefab, picks_upgrade_val]
      return l3
    when 4
      l4 << []
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def price_sheet?
    {
      siz: {
        0 => {
          val: 5,
          amount: -1
        },
        1 => {
          val: 6,
          amount: 100
        },
        2 => {
          val: 7,
          amount: 150
        },
        3 => {
          val: 8,
          amount: 300
        },
        4 => {
          val: 9,
          amount: 500
        },
        5 => {
          val: 10,
          amount: 1000
        }
      },
      max_foc: {
        0 => {
          val: 2,
          amount: -1
        },
        1 => {
          val: 3,
          amount: 200
        },
        2 => {
          val: 4,
          amount: 400
        },
        3 => {
          val: 5,
          amount: 800
        }
      },
      max_hp: {
        0 => {
          val: 10,
          amount: -1
        },
        1 => {
          val: 15,
          amount: 250
        },
        2 => {
          val: 20,
          amount: 500
        },
        3 => {
          val: 30,
          amount: 1000
        }
      },
      alc_tab_use: {
        0 => {
          val: 1,
          amount: -1
        },
        1 => {
          val: 2,
          amount: 250
        },
        2 => {
          val: 3,
          amount: 500
        },
        3 => {
          val: 4,
          amount: 1000
        },
        4 => {
          val: 5,
          amount: 1500
        }
      },
      shop_disc: {
        0 => {
          val: 0,
          amount: -1
        },
        1 => {
          val: 5,
          amount: 500
        },
        2 => {
          val: 10,
          amount: 1000
        },
        3 => {
          val: 20,
          amount: 1500
        },
        4 => {
          val: 30,
          amount: 2500
        },
        5 => {
          val: 50,
          amount: 5000
        }
      },
      picks: {
        0 => {
          val: 2,
          amount: -1
        },
        1 => {
          val: 3,
          amount: 5000
        },
        2 => {
          val: 4,
          amount: 10_000
        }
      }
    }
  end
end
