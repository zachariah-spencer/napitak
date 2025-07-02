class Transition
  attr_gtk
  attr :completed, :start_midway

  def initialize(start_midway: false)
    @start_midway = start_midway
    @duration = 0.5.seconds
    @start_tick = Kernel.tick_count
    @completed = false
    @a = 0.0
    @a = 255.0 if @start_midway
    @y = 0.0
    @y = GTK.args.grid.h if @start_midway
  end

  def tick
    if @start_midway
      @y = @y.lerp(GTK.args.grid.h * 2, 0.2)
    else
      if @start_tick.elapsed_time < (@duration / 2)
        @y = @y.lerp(GTK.args.grid.h, 0.2)
      else
        @y = @y.lerp(GTK.args.grid.h * 2, 0.2)
      end
    end

    #if @start_midway
    #  @a = @a.lerp(0, 0.2)
    #else
    #  if @start_tick.elapsed_time < (@duration / 2)
    #    @a = @a.lerp(255, 0.2)
    #  else
    #    @a = @a.lerp(0, 0.2)
    #  end
    #end
    @completed = true if @start_tick.elapsed_time >= @duration
  end

  def past_midway?
    @start_tick.elapsed_time >= @duration / 2
  end

  def prefab
    {
      x: 0,
      y: GTK.args.grid.h - @y, #(GTK.args.grid.h * 1.25) - ,
      w: GTK.args.grid.w,
      h: GTK.args.grid.h,
      r: 0,
      g: 0,
      b: 0,
      a: 255,
      primitive_marker: :solid
    }
  end
end
