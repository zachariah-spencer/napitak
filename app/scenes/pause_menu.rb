class PauseMenu < Scene
  
  def initialize()
    puts "PAUSED GAME"
    @pause_screen = "main"
    @journal_instance = nil
    @combat_instance = nil

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
    if Button.new(
         x: GTK.args.grid.w / 2 - 75,
         y: (GTK.args.grid.h - 100) / 1.25,
         w: 150,
         h: 75,
         text: "Resume"
       ).clicked?
      $game.toggle_pause
    end

    if Button.new(
         x: GTK.args.grid.w / 2 - 75,
         y: (GTK.args.grid.h - 100) / 1.5,
         w: 150,
         h: 75,
         text: "Journal"
       ).clicked?
      @journal_instance = Journal.new(pause_menu_instance: self)
      @pause_screen = "journal"
    end

    if Button.new(
         x: GTK.args.grid.w / 2 - 75,
         y: (GTK.args.grid.h - 100) / 1.88,
         w: 150,
         h: 75,
         text: "Settings"
       ).clicked?
      @pause_screen = "settings"
    end

    if Button.new(
         x: GTK.args.grid.w / 2 - 75,
         y: (GTK.args.grid.h - 100) / 2.5,
         w: 150,
         h: 75,
         text: "Quit"
       ).clicked?
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
    background ||= {
      x: 0,
      y: 0,
      w: GTK.args.grid.w,
      h: GTK.args.grid.h,
      r: 80,
      g: 80,
      b: 120,
      primitive_marker: :solid
    }

    encounter_label ||= {
      x: GTK.args.grid.w / 2,
      y: GTK.args.grid.h - 50,
      alignment_enum: 1,
      size_enum: 8,
      r: 255,
      g: 255,
      b: 255,
      text: "Paused",
      primitive_marker: :label
    }

    coming_soon_label ||= {
      x: GTK.args.grid.w / 2,
      y: (GTK.args.grid.h - 100) / 1.5 + 15,
      text: "(coming soon...)",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 150,
      g: 150,
      b: 150,
      a: 150,
      size_enum: -1
    }

    case screen
    when "main"
      @l0 << [background]
      @l4 << [encounter_label]
      @l3 << [
        resume_btn,
        journal_btn,
        coming_soon_label,
        settings_btn,
        exit_btn
      ]
    when "settings"
      @l0 << [background]
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
    {
      x: GTK.args.grid.w / 2 - 150,
      y: GTK.args.grid.h - 150,
      w: 32,
      h: 32,
      path: "sprites/back_button.png",
      angle: 0
    }
  end

  def go_back
    @pause_screen = "main"
  end

  def resume_btn
    Button
      .new(
        x: GTK.args.grid.w / 2 - 75,
        y: (GTK.args.grid.h - 100) / 1.25,
        w: 150,
        h: 75,
        text: "Resume"
      )
      .prefab
  end

  def journal_btn
    Button
      .new(
        x: GTK.args.grid.w / 2 - 75,
        y: (GTK.args.grid.h - 100) / 1.5,
        w: 150,
        h: 75,
        text: "Journal"
      )
      .prefab
  end

  def settings_btn
    Button
      .new(
        x: GTK.args.grid.w / 2 - 75,
        y: (GTK.args.grid.h - 100) / 1.88,
        w: 150,
        h: 75,
        text: "Settings"
      )
      .prefab
  end

  def exit_btn
    Button
      .new(
        x: GTK.args.grid.w / 2 - 75,
        y: (GTK.args.grid.h - 100) / 2.5,
        w: 150,
        h: 75,
        text: "Quit"
      )
      .prefab
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
