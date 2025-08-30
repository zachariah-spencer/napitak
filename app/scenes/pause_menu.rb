class PauseMenu < Scene
  def initialize()
    puts "PAUSED GAME"
    $AUDIO_SERVICE.play_song(:map_encounter)
    @pause_screen = "main"
    @journal_instance = nil
    @combat_instance = nil
    @journal_btn = Button.new(
         x: GTK.args.grid.w / 2,
         y: (GTK.args.grid.h - 100) / 1.5,
         w: 96,
         h: 48,
         text: "Journal"
       )
    @settings_btn = Button.new(
         x: GTK.args.grid.w / 2,
         y: (GTK.args.grid.h - 100) / 1.88,
         w: 96,
         h: 48,
         text: "Settings"
       )
    @restart_run_btn = Button.new(
         x: GTK.args.grid.w / 2,
         y: (GTK.args.grid.h - 100) / 1.25,
         w: 96,
         h: 48,
         text: "New Run"
       )
    @help_btn = Button.new(
         x: GTK.args.grid.w / 2,
         y: (GTK.args.grid.h - 100) / 2.5,
         w: 96,
         h: 48,
         text: "Help"
       )
    @quit_btn = Button.new(
         x: GTK.args.grid.w / 2,
         y: (GTK.args.grid.h - 100) / 3.75,
         w: 96,
         h: 48,
         text: "Quit"
       )

    @back_btn = Button.new(
      x: 64,
      y: GTK.args.grid.h - 16 - 16,
      w: 32,
      h: 32,
      path: "sprites/back_button-sheet-4.png",
      text: "",
      frame_length: 4,
      tile_rect: {
        x: 32,
        y: 0,
        w: 32,
        h: 32,
      },
      active: false
    )

    @buttons = [@journal_btn, @restart_run_btn, @quit_btn, @settings_btn, @help_btn, @back_btn]

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
    @buttons.each { |b| b.tick }
    screen_tick = "tick_#{@pause_screen}"
    send(screen_tick)
  end

  def tick_main
    pre_render("main")
    calc_main
  end

  def calc_main
    if @restart_run_btn.clicked?
      $game.new_run
    end

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
    if @back_btn.clicked?
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
      y: GTK.args.grid.h - 48,
      alignment_enum: 1,
      size_px: 128,
      r: 255,
      g: 255,
      b: 255,
      text: "PAUSED",
      font: $FONT,
      primitive_marker: :label
    }

    @l3 << [@back_btn.prefab]
    case screen
    when "main"
      @l0 << [background_solid, background]
      @l4 << [encounter_label]
      @l3 << [@journal_btn.prefab, @settings_btn.prefab, @quit_btn.prefab, @restart_run_btn.prefab, @help_btn.prefab]
      @back_btn.set_active(false)
    when "settings"
      @l0 << [background_solid, background]
      @l4 << [encounter_label]
      @back_btn.set_active(true)
    when "journal"
      @l0 << @journal_instance.render(0)
      @l1 << @journal_instance.render(1)
      @l2 << @journal_instance.render(2)
      @l3 << @journal_instance.render(3)
      @l3 << @journal_instance.render(4)
    else
    end
  end

  def go_back
    @pause_screen = "main"
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
