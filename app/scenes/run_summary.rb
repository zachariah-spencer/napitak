class RunSummary < Scene
  attr :sc_id

  def initialize(choices: 4, picks: 2)
    puts "init Run Summary Screen"
    @sc_id = "run_summary"

    @shop_btn =
      Button.new(
        x: GTK.args.grid.w / 2 - 75,
        y: 50,
        w: 150,
        h: 75,
        text: "Shop"
      )

    $files.save_data["mid_run"] = false
    $GAME.increment_runs_completed
  end

  def cleanup
  end

  def tick
    calc
  end

  def calc
    calc_buttons if !$GAME.input_locked
  end

  def calc_buttons
    if @shop_btn.clicked?
      $GAME.change_scene(prev_sc: @sc_id, next_scene: "meta_shop")
    end
    if GTK.args.inputs.mouse.click and
         Geometry.intersect_rect?(GTK.args.inputs.mouse, quit_btn)
      GTK.request_quit
    end
    if GTK.args.inputs.mouse.click and
         Geometry.intersect_rect?(GTK.args.inputs.mouse, new_run_btn)
      $GAME.new_run
    end
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

      l1 << [top_panel]
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
        text: "Run Summary",
        primitive_marker: :label
      }

      encounters_completed_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 + 150,
        alignment_enum: 1,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        text:
          "Encounters Completed: #{$encounter_manager.encounters_completed}",
        primitive_marker: :label
      }

      enemies_slain_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 + 100,
        alignment_enum: 1,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        text: "Enemies Slain: #{$encounter_manager.combats_won}",
        primitive_marker: :label
      }

      anodyne_earned_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h / 2 + 50,
        alignment_enum: 1,
        size_enum: 10,
        r: 255,
        g: 255,
        b: 255,
        text: "Anodyne Earned: #{$encounter_manager.calc_anodyne_earnings}",
        primitive_marker: :label
      }

      l2 << [
        encounter_label,
        encounters_completed_label,
        enemies_slain_label,
        anodyne_earned_label
      ]
      return l2
    when 3
      l3 << [new_run_btn, quit_btn, @shop_btn.prefab]
      return l3
    when 4
      l4 << []
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def quit_btn
    GTK.args.outputs[:quit_btn].w = 150
    GTK.args.outputs[:quit_btn].h = 75

    GTK.args.outputs[:quit_btn].primitives << {
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

    GTK.args.outputs[:quit_btn].primitives << {
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

    GTK.args.outputs[:quit_btn].primitives << {
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
      x: GTK.args.grid.w / 2 - 150 - 100,
      y: 50,
      w: 150,
      h: 75,
      angle: 0,
      path: :quit_btn,
      primitive_marker: :sprite
    }
  end

  def new_run_btn
    GTK.args.outputs[:new_run_btn].w = 150
    GTK.args.outputs[:new_run_btn].h = 75

    GTK.args.outputs[:new_run_btn].primitives << {
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

    GTK.args.outputs[:new_run_btn].primitives << {
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

    GTK.args.outputs[:new_run_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "New Run",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w / 2 + 100,
      y: 50,
      w: 150,
      h: 75,
      angle: 0,
      path: :new_run_btn,
      primitive_marker: :sprite
    }
  end
end
