class ShoutComponent

  # requires (x,y) worth of space to safely function without overlapping other screen elements
  def initialize(enemy_id: "wolf")
    rect = Layout.rect(row: 1, col: 15, w: 5, h: 3)
    @x = rect[:x]
    @y = rect[:y]
    @w = rect[:w]
    @h = rect[:h]
    @fx = rect[:x]
    @fy = rect[:y]
    @enemy_id = enemy_id
    @offensive_shouts = []
    @defensive_shouts = []
    @shout_tick = nil
    @selected_shout = ""
    @shout_alpha = 0
    @duration = 3.seconds

    load_shouts_from_json
  end

  def load_shouts_from_json
    shouts_json = GTK.read_file("data/enemy_shouts.json")
    all_shouts = GTK.parse_json(shouts_json)
    enemy_specific_shouts = all_shouts[@enemy_id]

    @offensive_shouts = enemy_specific_shouts["offense"]
    @defensive_shouts = enemy_specific_shouts["defense"]
  end

  def tick
    @shout_tick = nil if @shout_tick && @shout_tick.elapsed_time >= @duration
    return if @shout_tick == nil

    @x += (Math.cos(Kernel.tick_count * 0.05) * 0.1)
    @y += (Math.sin(Kernel.tick_count * 0.025) * 0.1)

    @shout_alpha = @shout_alpha.lerp(255, 0.09) if @shout_tick.elapsed_time < @duration * 0.8
    @shout_alpha = @shout_alpha.lerp(0, 0.09) if @shout_tick.elapsed_time >= @duration * 0.8
  end

  def shout_offensively
    @selected_shout = @offensive_shouts.sample
    @shout_tick = Kernel.tick_count
    reset_position
  end

  def shout_defensively
    @selected_shout = @defensive_shouts.sample
    @shout_tick = Kernel.tick_count
    reset_position
  end

  def reset_position
    @x = @fx
    @y = @fy
  end

  def prefab
    # render if shout_tick
    if @shout_tick
      prefab_array = []
      window = {
        primitive_marker: :solid,
        x: @x,
        y: @y,
        w: @w,
        h: @h,
        r: 0,
        g: 20,
        b: 40,
        a: @shout_alpha
      }
      prefab_array << window

      wrapped_text = String.wrapped_lines @selected_shout, 24
      start_line_y = (@h / 2 - 16) + ((wrapped_text.size - 1) * 12)
      prefab_array << wrapped_text.map_with_index do |t, i|
        {
          primitive_marker: :label,
          x: @x + (@w / 2),
          y: @y + start_line_y,
          anchor_x: 0.5,
          anchor_y: i,
          size_px: 22,
          r: 255,
          g: 0,
          b: 0,
          a: @shout_alpha,
          font: "fonts/eaglelake.ttf",
          text: "#{t}",
        }
      end
      
      prefab_array
    end
  end
end
