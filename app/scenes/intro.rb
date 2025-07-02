class Intro
  attr_gtk
  attr :sc_id

  def initialize()
    puts "init Intro Screen"
    @sc_id = "intro"
    @cutscene_duration = 3.seconds
    @start_tick = Kernel.tick_count
  end

  def cleanup
    $game.input_locked = false
  end

  def tick
    calc
  end

  def calc
    $game.change_scene(prev_sc: @sc_id, next_sc: "map") if @start_tick.elapsed_time >= @cutscene_duration || GTK.args.inputs.keyboard.key_down.o
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

      l2 << [encounter_label]
      return l2
    when 3
      l3 << [ ]
      return l3
    when 4
      l4 << [ ]
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end
end
