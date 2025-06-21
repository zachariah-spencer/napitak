class UpgradeLevelBarWidget
  attr_gtk
  attr

  def initialize(x:,y:,w:,h:,color: { r: 100, g: 0, b: 100},levels: 3, level: 1)
    @id = GameUtils.new_id?
    @x = x
    @y = y
    @w = w
    @h = h
    @color = color
    @levels = levels
    @level = level
    @l_w = @level * interval_size?
    @target_l_w = target_l_w?
  end

  def interval_size?
    @w / num_intervals?
  end

  def num_intervals?
    @levels
  end

  def target_l_w?
    @level * interval_size?
  end

  def tick 
    @l_w = @l_w.lerp(@target_l_w, 0.08)
  end

  def change_level(new_level)
    @level = new_level if (new_level >= 0 && new_level <= @levels)
    @target_l_w = target_l_w?
    
    @level
  end

  def prefab
    GTK.args.outputs[@id.to_s].w = @w
    GTK.args.outputs[@id.to_s].h = @h

    GTK.args.outputs[@id.to_s].primitives << {
        x: 0,
        y: 0,
        w: @w,
        h: @h,
        angle: 0,
        r: 100,
        g: 100,
        b: 100,
        a: 15,
        primitive_marker: :solid
      }

      GTK.args.outputs[@id.to_s].primitives << {
        x: 0,
        y: 0,
        w: @l_w,
        h: @h,
        angle: 0,
        r: @color[:r],
        g: @color[:g],
        b: @color[:b],
        a: 255,
        primitive_marker: :solid
      }

    num_intervals?.times do |i|
      GTK.args.outputs[@id.to_s].primitives << {
        x: ((i) * interval_size?),
        y: 0,
        w: @w,
        h: @h,
        angle: 0,
        r: 0,
        g: 0,
        b: 0,
        primitive_marker: :border
      }
    end

    {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      angle: 0,
      path: @id.to_s,
      primitive_marker: :sprite
    }
  end

end