class PauseMenu < Scene
  def initialize()
    puts "PAUSED GAME"
    $AUDIO_SERVICE.play_song(:pause_menu)
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
    master_volume = $AUDIO_SERVICE.volumes[:master]
    music_volume = $AUDIO_SERVICE.volumes[:music]
    sfx_volume = $AUDIO_SERVICE.volumes[:sfx]

    # Precompute bounds and start positions to avoid any first-frame flicker
    master_min_x = GTK.args.grid.w / 2 - 128
    master_max_x = GTK.args.grid.w / 2 - 4 + 128
    master_start_x = master_min_x + (master_volume * (master_max_x - master_min_x))
    @master_fader_handle = fader_handle(master_start_x, (GTK.args.grid.h - 48 - 128 - 48 - 9), master_min_x, master_max_x, :master)

    music_min_x = GTK.args.grid.w / 2 - 128
    music_max_x = GTK.args.grid.w / 2 - 4 + 128
    music_start_x = music_min_x + (music_volume * (music_max_x - music_min_x))
    @music_fader_handle = fader_handle(music_start_x, (GTK.args.grid.h - 48 - 128 - 96 - 48 - 9), music_min_x, music_max_x, :music)

    sfx_min_x = GTK.args.grid.w / 2 - 128
    sfx_max_x = GTK.args.grid.w / 2 - 4 + 128
    sfx_start_x = sfx_min_x + (sfx_volume * (sfx_max_x - sfx_min_x))
    @sfx_fader_handle = fader_handle(sfx_start_x, (GTK.args.grid.h - 48 - 128 - 96 - 96 - 48 - 9), sfx_min_x, sfx_max_x, :sfx)

    @l0 = []
    @l1 = []
    @l2 = []
    @l3 = []
    @l4 = []
  end

  def cleanup
    puts "cleanup"
    check_fader_bounds(@master_fader_handle)
    check_fader_bounds(@music_fader_handle)
    check_fader_bounds(@sfx_fader_handle)
    puts "UNPAUSED GAME"
  end

  def tick

    @buttons.each do |b| 
      b.tick
      b.active = @pause_screen == "main"
    end
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

    calc_fader_handle(@master_fader_handle)
    calc_fader_handle(@music_fader_handle)
    calc_fader_handle(@sfx_fader_handle)

    
  end

  def tick_journal
    if @journal_instance
      pre_render("journal")
      @journal_instance.tick
    end
  end

  def fader_line(y)
    {
      x: GTK.args.grid.w / 2 - 128,
      y: y,
      w: 256,
      h: 2,
      r: 255,
      g: 255,
      b: 255,
      a: 120,
      primitive_marker: :solid
    }
  end

  def fader_handle(x, y, min_x, max_x, control)
    {
      x: x,
      y: y,
      w: 4,
      h: 20,
      r: 255,
      g: 255,
      b: 255,
      a: 255,
      primitive_marker: :solid,
      min_x: min_x,
      max_x: max_x,
      percentage: ((x - min_x).to_f / (max_x - min_x)),
      control: control
    }
  end

  def calc_fader_handle_start_x(fader, volume)
    fader.min_x + (volume * (fader.max_x - fader.min_x))
  end

  def calc_fader_handle(fader)
    if GTK.args.inputs.mouse.click && GTK.args.inputs.mouse.intersect_rect?(fader)
      GTK.args.state.selected_ui = fader
    end

    if GTK.args.inputs.mouse.held && GTK.args.state.selected_ui == fader
      fader.x = GTK.args.inputs.mouse.x
      fader.x = fader.max_x if fader.x >= fader.max_x
      fader.x = fader.min_x if fader.x <= fader.min_x
      fader.percentage = ((fader.x - fader.min_x).to_f / (fader.max_x - fader.min_x)).round(2)
      $AUDIO_SERVICE.set_volume(channel: GTK.args.state.selected_ui.control, gain: GTK.args.state.selected_ui.percentage)
    end

    if GTK.args.inputs.mouse.up && GTK.args.state.selected_ui
      $files.save_data["settings"]["volumes"][fader.control.to_s] = fader.percentage
      GTK.args.state.selected_ui = nil
    end
  end

  def check_fader_bounds(fader)
    fader.x = fader.max_x if fader.x >= fader.max_x
    fader.x = fader.min_x if fader.x <= fader.min_x
    fader.percentage = ((fader.x - fader.min_x).to_f / (fader.max_x - fader.min_x)).round(2)
    # Apply the clamped value to the correct channel
    $AUDIO_SERVICE.set_volume(channel: fader.control, gain: fader.percentage)
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
      master_volume_label = {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 48 - 128,
      alignment_enum: 1,
      size_px: 32,
      r: 255,
      g: 255,
      b: 255,
      text: "Master Volume",
      font: $FONT,
      primitive_marker: :label
    }

    music_volume_label = {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 48 - 128 - 96,
      alignment_enum: 1,
      size_px: 32,
      r: 255,
      g: 255,
      b: 255,
      text: "Music Volume",
      font: $FONT,
      primitive_marker: :label
    }

    sfx_volume_label = {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 48 - 128 - 96 - 96,
      alignment_enum: 1,
      size_px: 32,
      r: 255,
      g: 255,
      b: 255,
      text: "Sound Effects Volume",
      font: $FONT,
      primitive_marker: :label
    }

    fader_lines = [
      fader_line(GTK.args.grid.h - 48 - 128 - 48), 
      fader_line(GTK.args.grid.h - 48 - 128 - 96 - 48), 
      fader_line(GTK.args.grid.h - 48 - 128 - 96 - 96 - 48)
    ] 


      @l0 << [background_solid, background]
      @l1 << [master_volume_label, music_volume_label, sfx_volume_label, fader_lines, @master_fader_handle, @music_fader_handle, @sfx_fader_handle]
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
end
