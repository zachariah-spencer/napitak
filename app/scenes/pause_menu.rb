class PauseMenu
  attr_gtk
  attr

  def initialize()
    puts "PAUSED GAME"
    @pause_screen = "main"
    @journal_instance = nil

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
    $game.toggle_pause if GTK.args.inputs.mouse.click and Geometry.intersect_rect?(GTK.args.inputs.mouse, resume_btn)
    if GTK.args.inputs.mouse.click and Geometry.intersect_rect?(GTK.args.inputs.mouse, journal_btn)
        @journal_instance = Journal.new(pause_menu_instance: self)
        @pause_screen = "journal" 
    end
    
    @pause_screen = "settings" if GTK.args.inputs.mouse.click and Geometry.intersect_rect?(GTK.args.inputs.mouse, settings_btn)
    GTK.request_quit if GTK.args.inputs.mouse.click and Geometry.intersect_rect?(GTK.args.inputs.mouse, exit_btn)
  end

  def tick_settings
    pre_render("settings")
    calc_settings
  end

  def calc_settings
    go_back if GTK.args.inputs.mouse.click and Geometry.intersect_rect?(GTK.args.inputs.mouse, back_btn)
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
        @l3 << [resume_btn, journal_btn, coming_soon_label, settings_btn, exit_btn]
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
        y: GTK.args.grid.h - 150 ,
        w: 40,
        h: 40,
        path: "sprites/circle/red.png",
        angle: 0
    }
  end

  def go_back
    @pause_screen = "main"
  end

  def resume_btn
    GTK.args.outputs[:resume_btn].w = 150
    GTK.args.outputs[:resume_btn].h = 75

    GTK.args.outputs[:resume_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:resume_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 70,
      g: 70,
      b: 150,
      a: 100,
      primitive_marker: :solid
    }

    GTK.args.outputs[:resume_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "Resume",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w / 2 - 75,
      y: (GTK.args.grid.h - 100) / 1.25 ,
      w: 150,
      h: 75,
      angle: 0,
      path: :resume_btn,
      primitive_marker: :sprite
    }
  end

  def journal_btn
    GTK.args.outputs[:journal_btn].w = 150
    GTK.args.outputs[:journal_btn].h = 75

    GTK.args.outputs[:journal_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:journal_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 70,
      g: 70,
      b: 150,
      a: 100,
      primitive_marker: :solid
    }

    GTK.args.outputs[:journal_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "Journal",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w / 2 - 75,
      y: (GTK.args.grid.h - 100) / 1.5,
      w: 150,
      h: 75,
      angle: 0,
      path: :journal_btn,
      primitive_marker: :sprite
    }
  end

  def settings_btn
    GTK.args.outputs[:settings_btn].w = 150
    GTK.args.outputs[:settings_btn].h = 75

    GTK.args.outputs[:settings_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:settings_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 70,
      g: 70,
      b: 150,
      a: 100,
      primitive_marker: :solid
    }

    GTK.args.outputs[:settings_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "Settings",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w / 2 - 75,
      y: (GTK.args.grid.h - 100) / 1.88,
      w: 150,
      h: 75,
      angle: 0,
      path: :settings_btn,
      primitive_marker: :sprite
    }
  end

  def exit_btn
    GTK.args.outputs[:exit_btn].w = 150
    GTK.args.outputs[:exit_btn].h = 75

    GTK.args.outputs[:exit_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:exit_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 70,
      g: 70,
      b: 150,
      a: 100,
      primitive_marker: :solid
    }

    GTK.args.outputs[:exit_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "Quit",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w / 2 - 75,
      y: (GTK.args.grid.h - 100) / 2.5,
      w: 150,
      h: 75,
      angle: 0,
      path: :exit_btn,
      primitive_marker: :sprite
    }
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
