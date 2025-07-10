class ShoutComponent

  # requires (x,y) worth of space to safely function without overlapping other screen elements
  def initialize(x: 500, y: 500, enemy_id: "wolf")
    @x = x
    @y = y
    @w = 256
    @h = 256
    @enemy_id = enemy_id
    @shouts = load_shouts_json
    @shout_tick = nil
    @selected_shout = ""
    @duration = 3.seconds
  end

  def load_shouts_json
    shouts_json = GTK.read_file("data/enemy_shouts.json")
    all_shouts = GTK.parse_json(shouts_json)
    puts all_shouts
    # return array of enemy specific shouts
    all_shouts[@enemy_id]
  end

  def tick
    @shout_tick = nil if @shout_tick && @shout_tick.elapsed_time >= @duration
  end

  def shout
    @selected_shout = @shouts.sample
    @shout_tick = Kernel.tick_count
  end

  def prefab
    # render if shout_tick
    if @shout_tick
      {
        primitive_marker: :label,
        x: @x,
        y: @y,
        size_px: 22,
        r: 255,
        g: 0,
        b: 0,
        text: @selected_shout
      }
    end
  end
end
