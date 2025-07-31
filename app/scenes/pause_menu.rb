class PauseMenu < Scene
  def initialize()
    puts "PAUSED GAME"
    @pause_screen = "main"
    @journal_instance = nil
    @combat_instance = nil
    @journal_btn = Button.new(
         x: GTK.args.grid.w / 2 - 48,
         y: (GTK.args.grid.h - 100) / 1.5,
         w: 96,
         h: 48,
         text: "Journal"
       )
    @settings_btn = Button.new(
         x: GTK.args.grid.w / 2 - 48,
         y: (GTK.args.grid.h - 100) / 1.88,
         w: 96,
         h: 48,
         text: "Settings"
       )
    @restart_run_btn = nil
    @quit_btn = Button.new(
         x: GTK.args.grid.w / 2 - 48,
         y: (GTK.args.grid.h - 100) / 2.5,
         w: 96,
         h: 48,
         text: "Quit"
       )

    @l0 = []
    @l1 = []
    @l2 = []
    @l3 = []
    @l4 = []
  end

  def cleanup
    puts "cleanup"
    puts "UNPAUSED GAME"
    save_settings
  end

  def tick
    screen_tick = "tick_#{@pause_screen}"
    send(screen_tick)
  end

  def tick_main
    pre_render("main")
    calc_main
  end

  def calc_main
    if @journal_btn.clicked?
      @journal_instance = Journal.new(pause_menu_instance: self)
      @pause_screen = "journal"
    end

    if @settings_btn.clicked?
      @pause_screen = "settings"
    end

    if @quit_btn.clicked?
      GTK.request_quit
    end
  end

  def tick_settings
    pre_render("settings")
    calc_settings
  end

  def calc_settings
    if GTK.args.inputs.mouse.click and
         Geometry.intersect_rect?(GTK.args.inputs.mouse, back_btn)
      go_back
    end
  end

  def tick_journal
    if @journal_instance
      pre_render("journal")
      @journal_instance.tick
    end
  end

  def pre_render(screen)
    # Clear buffers
    @l0.clear
    @l1.clear
    @l2.clear
    @l3.clear
    @l4.clear

    # Universal pause menu sprites
    bg_tile_index = 0.frame_index(24, 1.0.seconds, true)
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

    encounter_label ||= {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 50,
      alignment_enum: 1,
      size_px: 40,
      r: 255,
      g: 255,
      b: 255,
      text: "PAUSED",
      font: "fonts/eaglelake.ttf",
      primitive_marker: :label
    }

    case screen
    when "main"
      @l0 << [background_solid, background]
      @l4 << [encounter_label]
      @l3 << [@journal_btn.prefab, @settings_btn.prefab, @quit_btn.prefab]
    when "settings"
      @l0 << [background_solid, background]
      @l4 << [encounter_label]
      @l3 << [back_btn]
    when "journal"
      @l0 << @journal_instance.render(0)
      @l1 << @journal_instance.render(1)
      @l2 << @journal_instance.render(2)
      @l3 << @journal_instance.render(3)
      @l3 << @journal_instance.render(4)
    else
    end
  end

  def back_btn
    f_i = 0.frame_index(count: 4, hold_for: 15, repeat: true)
    {
      x: 48,
      y: GTK.args.grid.h - 16 - 32,
      w: 32,
      h: 32,
      path: "sprites/back_button-sheet-4.png",
      tile_x: 32 * f_i,
      tile_y: 0,
      tile_w: 32,
      tile_h: 32,
      angle: 0
    }
  end

  def go_back
    @pause_screen = "main"
  end

  def journal_btn
    Button.new(
      x: GTK.args.grid.w / 2 - 75,
      y: (GTK.args.grid.h - 100) / 1.5,
      w: 150,
      h: 75,
      text: "Journal"
    ).prefab
  end

  def settings_btn
    Button.new(
      x: GTK.args.grid.w / 2 - 75,
      y: (GTK.args.grid.h - 100) / 1.88,
      w: 150,
      h: 75,
      text: "Settings"
    ).prefab
  end

  def exit_btn
    Button.new(
      x: GTK.args.grid.w / 2 - 75,
      y: (GTK.args.grid.h - 100) / 2.5,
      w: 150,
      h: 75,
      text: "Quit"
    ).prefab
  end

  def render(layer_num)
    case layer_num
    when 0
      return @l0
    when 1
      return @l1
    when 2
      return @l2
    when 3
      return @l3
    when 4
      return @l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def save_settings
  end
end
