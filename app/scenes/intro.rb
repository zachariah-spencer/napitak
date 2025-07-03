class Intro
  attr_gtk
  attr :sc_id

  def initialize()
    puts "init Intro Screen"
    @sc_id = "intro"
    @cutscene_duration = 18.seconds
    @start_tick = Kernel.tick_count
    @crashing_sound_played_tick = nil
    @crashing_sound_completed = false

    # STEP 0
    @steps_completed = 0
    GameUtils.announce_lg(
      text: "Something is stirring in the night just outside the window of your alchemy laboratory... You feel a sense of deep dread as you peer through the glass pane and see only shadow...", 
      duration: 5.0.seconds,
      x: GTK.args.grid.w / 2 - 400,
      y: GTK.args.grid.h / 2 - 125,
      )
  end

  def cleanup
    $announcement_manager.clear_announcements_queue
  end

  def tick
    if GameUtils.current_announcement_completed?
      case @steps_completed
      when 0
        # STEP 1
        @steps_completed = 1
        GameUtils.announce_lg(
          text: "And then...", 
          duration: 2.0.seconds,
          x: GTK.args.grid.w / 2 - 400,
          y: GTK.args.grid.h / 2 - 125,
        )
      when 1
        @steps_completed = 2
      when 4
        # STEP 4
        @steps_completed = 5
        $game.change_scene(prev_sc: @sc_id, next_sc: "combat_tutorial")
      end
    end


    # STEP 2 START
    if @steps_completed == 2 && !@crashing_sound_played_tick
      @crashing_sound_played_tick = Kernel.tick_count
    end

    # STEP 2 FINISH
    if @crashing_sound_played_tick && @crashing_sound_played_tick.elapsed_time >= 2.seconds && !@crashing_sound_completed
      @steps_completed = 3
      @crashing_sound_completed = true
    end

    # STEP 3
    if @steps_completed == 3 && $announcement_manager.no_announcements?
      @steps_completed = 4
      GameUtils.announce_lg(
        text: "The sound of splintering wood startles you to your feet as an absence of light appears to fill the room and begins wrecking your research! A chill runs down your spine as you grab your potion satchel and prepare to defend yourself.", 
        duration: 5.0.seconds,
        x: GTK.args.grid.w / 2 - 400,
        y: GTK.args.grid.h / 2 - 125,
      )
    end

    $game.change_scene(prev_sc: @sc_id, next_sc: "combat_tutorial") if GTK.args.inputs.keyboard.key_down.o
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
        r: 0,
        g: 0,
        b: 0,
        primitive_marker: :solid
      }

      l0 << [background]
      return l0
    when 1
      l1 << []
      return l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 50,
        alignment_enum: 1,
        size_px: 26,
        r: 255,
        g: 255,
        b: 255,
        text: "Intro Sequence",
        primitive_marker: :label
      }

      # l2 << [encounter_label]
      return l2
    when 3
      l3 << []
      return l3
    when 4
      l4 << []
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end
end
