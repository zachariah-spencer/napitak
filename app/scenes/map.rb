class Map < Scene
  attr :sc_id

  def initialize
    @sc_id = "map"

    @choices = []
    @encounter_manager = $encounter_manager
    if $files.save_data["scene"] == "map" and $files.save_data["map_layer"] != 1
      choice_ids = $files.save_data["map_choices"]
      choice_ids.each { |id| @choices << EncounterCard.new(id) }
      puts @choices
    else
      @choices = @encounter_manager.next_choices?
    end
  end

  def tick
    calc_input if !$game.input_locked

    @choices.each { |c| c.tick }
  end

  def calc_input
    @choices.each do |c|
      if (clicked = c.pop_clicked)
        if $ENCOUNTERS[clicked[:id]].is_combat
          $game.change_scene(
            prev_sc: "map",
            next_scene: "combat",
            args: [clicked[:id]]
          )
        else
          $game.change_scene(prev_sc: "map", next_scene: clicked[:id])
        end
      end
    end
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    choice_cards ||= []

    count = @choices.size
    spacing = 256 - 16
    center = GTK.args.grid.w / 2

    # total span from first to last card
    total_span = spacing * (count - 1)
    # x-coordinate of the first card
    start_x = center - (total_span / 2.0)

    @choices.each_with_index do |c, idx|
      c.f_pos.x = (start_x + spacing * idx) - (c.fw / 2)
      c.f_pos.y = GTK.args.grid.h / 2 - 112.5

      choice_cards << c.prefab
    end

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
        primitive_marker: :solid,
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
