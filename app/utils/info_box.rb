class InfoBox
  attr_reader :on_complete, :id, :duration, :start_frame
  # all active boxes
  @@boxes       = {}
  @@next_id = 1
  # frame counter (increments each time .render is called)
  @@frame_count = 0
  @@pending_next_frame    = []

  # call this in your main tick to update & draw all boxes
  def self.render(args)
    # 0) first thing: fire last frame’s callbacks
    @@pending_next_frame.each(&:call)
    @@pending_next_frame.clear

    @@frame_count += 1

    # 1) expire any boxes whose time is up or were stopped,
    #    but queue their callbacks for next frame
    expired = @@boxes.values.select do |box|
      box.stopped? ||
        (box.duration && (@@frame_count - box.start_frame) >= box.duration)
    end

    expired.each do |box|
      @@pending_next_frame << box.on_complete if box.on_complete
      @@boxes.delete(box.id)
    end

    # 2) draw whatever remains
    @@boxes.values.each { |box| box.draw(args) }
  end

  # create a new InfoBox
  #   x, y      -- bottom‐left corner
  #   width, height
  #   text      -- string to show
  #   duration  -- optional number of ticks to live (omit to show until stopped)
  def initialize(x:, y:, width:, height:, text:, duration: nil, on_complete: nil)
    @id = @@next_id
    @@next_id += 1
    @x, @y, @width, @height = x, y, width, height
    @text      = text
    @duration  = duration
    @start_frame = @@frame_count
    @stopped     = false
    @on_complete = on_complete

    @@boxes[@id] = self
  end

  # manually hide it
  def stop
    @stopped = true
  end

  def stopped?
    @stopped
  end

  # allow chain to stop by id
  def self.stop_by_id(id)
    @@boxes[id]&.stop
  end

  # when hiding, remove from registry & fire callback
  def hide?
    done = @stopped || (@duration && (@@frame_count - @start_frame) >= @duration)
    if done
      @on_complete&.call
      @@boxes.delete(@id)
    end
    done
  end

  # draw the box + scaled text
  def draw(args)
    padding = 8
    base_size = @height

    # measure at base size
    measured_w, measured_h = args.gtk.calcstringbox(@text, base_size)
    # figure scale so text fits within width−2*padding and height−2*padding
    scale = [
      (@width  - padding * 2) / measured_w.to_f,
      (@height - padding * 2) / measured_h.to_f
    ].min
    font_size = (base_size * scale / 2.2).floor

    # re-measure at final size
    text_w, text_h = args.gtk.calcstringbox(@text, font_size)

    # background
    args.outputs.primitives << {
      x: @x, y: @y, w: @width, h: @height,
      r:  0, g:  0, b:  0, a: 100,
      primitive_marker: :solid
    }
    # border
    # args.outputs.primitives << {
    #   x: @x, y: @y, w: @width, h: @height,
    #   r:255, g:255, b:255, a:255,
    #   border_thickness: 2,
    #   primitive_marker: :border
    # }
    # centered text
    args.outputs.primitives << {
      x: @x + ((@width  - text_w) / 2).floor,
      y: @y + ((@height + text_h) / 2).floor,
      text: @text,
      size_enum: font_size,
      r:255, g:255, b:255,
      primitive_marker: :label
    }
  end
end
