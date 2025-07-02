class Transition
  attr_gtk

  def initialize
    @duration = 1.seconds
    @start_tick = Kernel.tick_count
    @midway_tick = (@start_tick + @duration) / 2
    @completed = false
    @a = 0
  end

  def tick
    if @start_tick.elapsed_time < @midway_tick
      @a = @a.lerp(255, 0.5)
    else
      @a = @a.lerp(0, 0.5)
    end

    @completed = true if past_midway? && !@completed
  end

  def past_midway?
    @start_tick.elapsed_time < @midway_tick
  end

  def prefab
    {
      x: 0,
      y: 0,
      w: GTK.args.grid.w,
      h: GTk.args.grid.h,
      r: 0,
      g: 0,
      b: 0,
      a: @a,
    }
  end

end