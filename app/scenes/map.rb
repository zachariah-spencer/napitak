require "app/services/encounter_manager"

class Map
  attr_gtk
  attr

  def initialize
    @sc_id = "map"
    @encounter_manager = EncounterManager.new
  end

  def tick
    if GTK.args.inputs.keyboard.key_down.l or GTK.args.inputs.touch
      $game.change_scene(prev_sc: "map", next_sc: @encounter_manager.rand_encounter?)
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

      l0 << [ background ]

      l0
    when 1
      left_panel ||= {
        x: 0,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid
      }

      right_panel ||= {
        x: GTK.args.grid.w - 200,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid
      }

      l1 << [left_panel, right_panel]
      l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 50,
        alignment_enum: 1,
        size_enum: 8,
        r: 255,
        g: 255,
        b: 255,
        text: "Map",
        primitive_marker: :label
      }

      l2 << [
        encounter_label,
      ]
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
  end
end
