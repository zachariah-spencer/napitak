class StatusEffectListWidget
  attr_gtk
  attr

  def initialize(x:, y:, hover_rect:)
    @x = x
    @y = y
    @hover_rect = hover_rect
    @hovered = false
    @a = 0
    @da = 0
  end

  def tick
    @hovered = hovered?
    @da = @hovered ? 255 : 0
    @a = @a.lerp(@da, 0.1)
  end

  def hovered?
    GTK.args.inputs.mouse.intersect_rect?(@hover_rect)
  end

  def list_size?
    $player.status_effects.length
  end

  def prefab
    widget_h = 32 + (list_size? * 24)
    widget_y = @y - widget_h
    background = {
      x: @x,
      y: widget_y,
      w: 256,
      h: widget_h,
      r: 40,
      g: 40,
      b: 40,
      a: @a - 75,
      primitive_marker: :solid
    }
    label = {
      x: @x + 128,
      y: widget_y + widget_h - 18,
      anchor_x: 0.5,
      anchor_y: 0.5,
      size_px: 26,
      r: 255,
      g: 255,
      b: 255,
      a: @a,
      font: "fonts/eaglelake.ttf",
      text: "Effects"
    }

    list = []
    $player.status_effects.each_with_index do |effect, i|
      list << {
        x: @x + 128,
        y: widget_y + widget_h - 42 - (i * 24),
        anchor_x: 0.5,
        alignment_enum: 0,
        anchor_y: 0.5,
        size_px: 18,
        r: 255,
        g: 255,
        b: 255,
        a: @a,
        font: "fonts/eaglelake.ttf",
        text: "- #{effect.label?}"
      }
    end
    {
      background: background,
      label: label,
      list: list
    }
  end

end