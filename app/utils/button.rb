class Button
  attr_gtk
  attr :text

  def initialize(
    x: GTK.args.grid / 2,
    y: GTK.args.grid.h / 2,
    w: 128,
    h: 128,
    text: "BUTTON",
    font_color: { r: 255, g: 255, b: 255 },
    background_color: { r: 200, g: 0, b: 0 }
  )
    @id = GameUtils.new_id?
    @x = x
    @y = y
    @w = w
    @h = h
    @text = text
    @background_color = background_color
    @font_color = font_color
    @rand_seed = Numeric.rand(0..4)
  end

  def prefab
    f_i = @rand_seed.frame_index(start_at: @rand_seed,
                              frame_count: 3,
                              hold_for: 0.5.seconds,
                              repeat: true)
    GTK.args.outputs[@id.to_s].w = @w
    GTK.args.outputs[@id.to_s].h = @h

    GTK.args.outputs[@id.to_s].primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      angle: 0,
      r: 255,
      g: 255,
      b: 255,
      path: "sprites/wide_button_frame-sheet-6.png",
      primitive_marker: :sprite,
      tile_x: 96 * f_i,
      tile_y: 0,
      tile_w: 96,
      tile_h: 48
    }

    GTK.args.outputs[@id.to_s].primitives << {
      x: @w / 2,
      y: @h / 2,
      text: @text,
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_px: 20,
      font: "fonts/eaglelake.ttf"
    }

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

  def clicked?
    Geometry.intersect_rect?(GTK.args.inputs.mouse, rect) &&
      GTK.args.inputs.mouse.click
  end

  def rect
    [@x, @y, @w, @h]
  end
end
