class Announcement
  attr_gtk
  attr :text, :tutorial_id, :message_completed

  def initialize(x: Grid.w / 2 - 400, y: Grid.h - 250 - 50, text:, duration:, large: false, tutorial_id: -1)
    @tutorial_id = tutorial_id
    @id = GameUtils.new_id?
    @x = x
    @y = y
    if large
      @w = 800
      @h = 250
      @px_size = 30
      @max_chars_per_line = 70
    else
      @w = 400
      @h = 125
      @px_size = 22
      @max_chars_per_line = 40
    end
    
    @text = text
    @duration = duration
    @created_tick = nil
    @a = 0
    @completed = false
  end

  def start_message
    @created_tick = Kernel.tick_count
  end

  def tick
    if @created_tick
      @a = @a.lerp(255, 0.1) if !message_over?
      @a = @a.lerp(0, 0.1) if message_over?
    end
  end

  def message_over?
    if @created_tick
      @created_tick.elapsed_time >= @duration
    else
      false
    end
  end

  def message_completed?
    if @created_tick
      message_over? && @a <= 10
    else
      false
    end
  end

  def prefab
    # define total dimensions of announcement box for rendering
    GTK.args.outputs["announcement_#{@id}"].w = @w
    GTK.args.outputs["announcement_#{@id}"].h = @h

    # render box as the background to lay text over
    GTK.args.outputs["announcement_#{@id}"].primitives << {
      x: 0,
      y: 0,
      w: @w,
      h: @h,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid,
    }

    # render labels for each line of the text until the message is fully rendered
    multi_line_text = String.wrapped_lines @text, @max_chars_per_line
    GTK.args.outputs["announcement_#{@id}"].primitives << multi_line_text.map_with_index do |s, i|
      {
        x: @w / 2,
        y: @h / 2 + @px_size,
        text: s.to_s,
        anchor_x: 0.5,
        anchor_y: i,
        r: 255,
        g: 255,
        b: 255,
        size_px: @px_size,
        primitive_marker: :label,
        font: "fonts/eaglelake.ttf",
      }
    end

    # return completed render target cache for calling class to use for rendering
    {
      x: @x,
      y: @y,
      w: @w,
      h: @h,
      a: @a,
      path: "announcement_#{@id}",
    }
    
  end
end