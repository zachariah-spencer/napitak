class Transition
  attr_gtk
  attr :completed, :start_midway

  def initialize(start_midway: false)
    @start_midway = start_midway
    @duration = 0.8.seconds
    @start_tick = Kernel.tick_count
    @completed = false
    @a = 0.0
    @a = 255.0 if @start_midway
  end

  def tick
    if @start_midway
      @a = @a.lerp(0, 0.1)
    else
      if @start_tick.elapsed_time < (@duration / 2)
        @a = @a.lerp(255, 0.1)
      else
        @a = @a.lerp(0, 0.1)
      end
    end
    puts @start_tick.elapsed_time
    @completed = true if @start_tick.elapsed_time >= @duration
  end

  def past_midway?
    @start_tick.elapsed_time >= @duration / 2
  end

  def prefab
    {
      x: 0,
      y: 0,
      w: GTK.args.grid.w,
      h: GTK.args.grid.h,
      r: 0,
      g: 0,
      b: 0,
      a: @a,
      primitive_marker: :solid,
    }
  end

end