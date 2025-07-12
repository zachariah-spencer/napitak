class MetaShop
  attr_gtk
  attr :sc_id

  def initialize()
    puts "init Roleplay Encounter"
    @sc_id = "rp_encounter_generic"
  end

  def ready
  end

  def cleanup
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
        r: 50,
        g: 50,
        b: 70,
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
        size_px: Math.sin(Kernel.tick_count * 0.08) * 4 + 40,
        r: 255,
        g: 255,
        b: 255,
        text: "Roleplay Encounter",
        primitive_marker: :label
      }

      l2 << [encounter_label]
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
