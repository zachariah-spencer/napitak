class PauseMenu
  attr_gtk
  attr

  def initialize()
    puts "PAUSED GAME"
  end

  def cleanup
    puts "cleanup"
    puts "UNPAUSED GAME"
    save_settings
  end

  def tick
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
        r: 80,
        g: 80,
        b: 120,
        primitive_marker: :solid
      }

      l0 << [background]
      return l0
    when 1

      l1 << []
      return l1
    when 2

      l2 << []
      return l2
    when 3

      l3 << []
      return l3
    when 4
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

      l4 << [ encounter_label ]
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def save_settings
    
  end
end
