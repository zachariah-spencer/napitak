class Button
  attr_gtk
  attr :text, :background_color, :active

  def initialize(
    x: GTK.args.grid / 2,
    y: GTK.args.grid.h / 2,
    w: 128,
    h: 128,
    text: "BUTTON",
    font_color: { r: 255, g: 255, b: 255 },
    background_color: { r: 255, g: 255, b: 255 },
    path: "sprites/wide_button_frame-sheet-6.png",
    tile_rect: { x: 96, y: 0, w: 96, h: 48 },
    frame_length: 6,
    text_size_px: nil,
    anchor_y: 0.5,
    active: true
  )
    @id = GameUtils.new_id?
    @x = x
    @y = y
    @w = w
    @h = h
    @fw = w
    @fh = h
    @normal_w = w
    @normal_h = h
    @hovered_w = @normal_w * 1.15
    @hovered_h = @normal_h * 1.15
    @path = path
    @frame_length = frame_length
    @tile_rect = tile_rect
    @text = text
    @background_color = background_color
    @a = 255
    @da = 255
    @font_color = font_color
    @rand_seed = Numeric.rand(0..4)
    @hovered = false
    @anim_speed = 0.5.seconds
    @text_size_px = text_size_px
    @anchor_y = anchor_y
    @active = active
    @da = @active ? 255 : 0
    @a = @active ? 255 : 0
  end

  def set_active(val)
    return if @active == val
    @active = val
    @da = @active ? 255 : 0
  end

  def tick
    if $game.input_locked
      hovered_last_tick = false
      @hovered = false
    else
      hovered_last_tick = @hovered
      @hovered = GTK.args.inputs.mouse.intersect_rect?(rect)
      $AUDIO_SERVICE.play_sound(:button_hover) if @hovered != hovered_last_tick && @hovered
      $AUDIO_SERVICE.play_sound(:button_unhover) if @hovered != hovered_last_tick && !@hovered

      @anim_speed = @hovered ? 0.1.seconds : 0.5.seconds
      @fw = @hovered ? @hovered_w : @normal_w
      @fh = @hovered ? @hovered_h : @normal_h

      @w = @normal_w / 1.5 if clicked?
      @h = @normal_h / 1.5 if clicked?

      @w = @w.lerp(@fw, 0.2)
      @h = @h.lerp(@fh, 0.2)
      @a = @a.lerp(@da, 0.2)
    end
  end

  def update_alpha(a)
    @a = a
  end

  def rect
    [@x - (@w / 2), @y - (@h / 2), @w, @h]
  end

  def hovered_rect
    [@x - (@fw / 2), @y - (@fh / 2), @fw, @fh]
  end

  def prefab
    f_i = 0.frame_index(start_at: @rand_seed,
                              count: @frame_length,
                              hold_for: @anim_speed,
                              repeat: true)
    GTK.args.outputs[@id.to_s].w = @w
    GTK.args.outputs[@id.to_s].h = @h

    GTK.args.outputs[@id.to_s].primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      angle: 0,
      r: @background_color[:r],
      g: @background_color[:g],
      b: @background_color[:b],
      a: @a,
      path: @path,
      primitive_marker: :sprite,
      tile_x: @tile_rect[:x] * f_i,
      tile_y: @tile_rect[:y],
      tile_w: @tile_rect[:w],
      tile_h: @tile_rect[:h]
    }

    GTK.args.outputs[@id.to_s].primitives << {
      x: @w / 2,
      y: @h / 2,
      text: @text,
      anchor_x: 0.5,
      anchor_y: @anchor_y,
      r: 255,
      g: 255,
      b: 255,
      a: @a,
      size_px: @text_size_px || (@w / 4),
      font: $FONT
    }

    {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      anchor_x: 0.5,
      anchor_y: 0.5,
      angle: 0,
      path: @id.to_s,
      primitive_marker: :sprite
    }
  end

  def clicked?
    return false if $game.input_locked || !@active
    if Geometry.intersect_rect?(GTK.args.inputs.mouse, hovered_rect) &&
      GTK.args.inputs.mouse.click
      $AUDIO_SERVICE.play_sound(:button_press)
      true
    else
      false
    end
  end
end
