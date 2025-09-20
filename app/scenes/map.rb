class Map < Scene
  attr :sc_id

  def initialize
    @sc_id = "map"

    @choices = []
    @selection = nil
    @selected_card_ref = nil
    @selection_made_tick = false
    @selection_handled = false
    @encounter_manager = $encounter_manager
    if $files.save_data["scene"] == "map" and $files.save_data["map_layer"] != 1
      choice_ids = $files.save_data["map_choices"]
      choice_ids.each { |id| @choices << EncounterCard.new(id) }
      puts @choices
    else
      @choices = @encounter_manager.next_choices?
    end

    count = @choices.size
    spacing = 64
    card_width = @choices[0].w
    center = GTK.args.grid.w / 2

    # total span from first to last card
    total_span = (spacing + card_width) * (count - 1)
    # x-coordinate of the first card
    start_x = center - (total_span / 2.0)

    @choices.each_with_index do |c, idx|
      c.instant_set_position(
        # pos is center; no need to subtract half width
        x: (start_x + ((spacing + card_width) * idx)),
        y: GTK.args.grid.h / 2
      )
    end

    $AUDIO_SERVICE.play_song(:map_encounter)
  end

  def tick
    calc_input if !$GAME.input_locked
    handle_selection_animation if @selection_made_tick
    @choices.each { |c| c.tick }
  end

  def calc_input
    @choices.each do |c|
      if (c.selected)
        @selection = c.pop_clicked
        @selected_card_ref = c
        @selection_made_tick = Kernel.tick_count
        $GAME.input_locked = true
      end
    end
  end

  def handle_selection_animation
    @choices.each do |c|
      c.fade_out if c != @selected_card_ref

      if c == @selected_card_ref &&
           @selection_made_tick.elapsed_time >= 0.1.seconds
        c.fw = 300
        c.fh = 300
        # pos is center (anchor 0.5)
        c.f_pos.x = GTK.args.grid.w / 2
        c.f_pos.y = GTK.args.grid.h / 2
      end
    end

    if @selection_made_tick.elapsed_time >= 1.0.seconds && !@selection_handled
      handle_selection
    end
  end

  def handle_selection
    @selection_handled = true

    if $ENCOUNTERS[@selection[:id]].is_combat
      $GAME.change_scene(
        prev_sc: "map",
        next_scene: "combat",
        args: [@selection[:id]]
      )
    else
      $GAME.change_scene(prev_sc: "map", next_scene: @selection[:id])
    end
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    choice_cards ||= []
    @choices.each { |c| choice_cards << c.prefab }
    bg_tile_index = 0.frame_index(24, 1.0.seconds, true)

    case layer_num
    when 0
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

      l0 << [background_solid, background]

      l0
    when 1
      l1 << []
      l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 50,
        alignment_enum: 1,
        size_px: Math.sin(Kernel.tick_count * 0.08) * 4 + 40,
        r: 255,
        g: 255,
        b: 255,
        text: "Please Select an Encounter",
        font: $FONT,
        size_px: 36,
        primitive_marker: :label
      }

      l2 << [encounter_label, choice_cards]
      l2
    when 3
      l3 << []
      l3
    when 4
      l4 << []
      l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def calc
  end

  def cleanup
    $files.save_data["map_layer"] = ($encounter_manager.map_layer)
  end
end
