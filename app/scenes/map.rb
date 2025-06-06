require "app/services/encounter_manager"

class Map
  attr_gtk
  attr

  def initialize
    @sc_id = "map"
    @encounter_manager = $encounter_manager
    @encounter_manager.next_choices?

    if @encounter_manager.encounters_completed? == 0 and $tutorials
      @tutorials = InfoBoxChain.new(
        [
        { x:  GTK.args.grid.w / 2 - 150, y: 500, width:300, height:80, text:"Welcome, alchemist!", duration:90 },
        { x: GTK.args.grid.w / 2 - 400, y: 500, width:800, height:80, text:"Click the card to enter your Laboratory!",   duration:90 },
        ]
      )
    end
  end

  def tick
    @encounter_manager.choices?.each do |c|
      c.tick

      if (clicked = c.pop_clicked)
        @tutorials&.cancel if @tutorials

        $game.change_scene(
          prev_sc: "map",
          next_sc: clicked[:id]
          )
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

    count = @encounter_manager.choices?.size
    spacing = 275
    center = GTK.args.grid.w / 2

    # total span from first to last card
    total_span = spacing * (count - 1)
    # x-coordinate of the first card
    start_x = center - (total_span / 2.0)

    @encounter_manager.choices?.each_with_index do |c, idx|
      c.f_pos.x = (start_x + spacing * idx) - (c.fw / 2)
      c.f_pos.y = GTK.args.grid.h / 2 - 112.5

      choice_cards << c.prefab
    end

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
  end
end
