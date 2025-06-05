class ScrollListWidgetH
  attr_reader :selected_item

  def initialize(items:, x:, y:, w:, h:, uid:, item_width: 120)
    @items = items
    @x, @y = x, y
    @width = w
    @height = h
    @item_width = item_width
    @item_height = @height
    @scroll_x = 0
    @scroll_vel = 0
    @hovered_idx = nil
    @selected_item = nil
    @uid = uid

    # Scrollbar state
    @scroll_bar_height = 8
    @scroll_bar_dragging = false
    @scroll_bar_drag_start_mouse_x = 0
    @scroll_bar_thumb_x_at_drag_start = 0
  end

  def rect
    [@x, @y, @width, @height]
  end

  def add_item(item)
    @items.unshift(item)
    item
  end

  def remove_item(item)
    @items.delete(item)
    item
  end

  # reset selection, handle A/D scrolling and scrollbar drag, then detect clicks
  def tick(inputs)
    @selected_item = nil
    handle_keys(inputs)
    handle_scroll_bar(inputs)
    detect_click(inputs)
  end

  # after render/tick, caller can do widget.pop_clicked
  def pop_clicked
    item = @selected_item
    @selected_item = nil
    item
  end

  def visible?(item_x)
    item_x < @x + @width && (item_x + @item_width) > @x
  end

  # draws into the RT and composites it back
  def render
    path = "sl_widget_rt_" + @uid.to_s

    # 1) (Re)initialize the RT buffer at the widget's size
    GTK.args.outputs[path].w = @width
    GTK.args.outputs[path].h = @height + @scroll_bar_height + 4 # extra space for scrollbar

    # background for main area
    GTK.args.outputs[path].solids << [0, @scroll_bar_height + 4, @width, @height, 0, 0, 0, 160]

    # draw items
    @items.each_with_index do |item, idx|
      local_x = (idx * @item_width) - @scroll_x
      local_y = @scroll_bar_height + 4

      # skip fully off‐screen columns
      next if local_x + @item_width < 0
      next if local_x > @width

      # slot background
      color = (@hovered_idx == idx) ? [80, 80, 80] : [100, 100, 100]
      GTK.args.outputs[path].solids << [
        local_x + 5,
        local_y + 5,
        @item_width - 10,
        @item_height - 10,
        *color
      ]

      # label (centered horizontally within each tile)
      GTK.args.outputs[path].labels << {
        x: local_x + (@item_width / 2),
        y: local_y + (@item_height / 2) - 8,
        text: item.name,
        size_enum: 1,
        alignment_enum: 1
      }

      if item.id[0] == "p"
        # uses left‐aligned label for potions
        GTK.args.outputs[path].labels << {
          x: local_x + (@item_width) - 20,
          y: local_y + (@item_height / 2) + 25,
          text: "#{item.uses_left}/#{item.max_uses}",
          alignment_enum: 2,
          size_enum: 1
        }

        # icon for potions
        GTK.args.outputs[path].sprites << {
          x: local_x + 20,
          y: local_y + (@item_height / 2) - 16,
          w: 32,
          h: 32,
          path: item.img
        }
      elsif item.id[0] == "i"
        # icon for ingredients
        GTK.args.outputs[path].sprites << {
          x: local_x + (@item_width / 2) - 16,
          y: local_y + (@item_height / 2),
          w: 32,
          h: 32,
          path: item.img
        }
      end
    end

    # draw scrollbar track
    total_width = @items.size * @item_width
    max_offset = [0, total_width - @width].max
    track_y = 2
    GTK.args.outputs[path].solids << [
      0,
      track_y,
      @width,
      @scroll_bar_height,
      50, 50, 50, 200
    ]

    if total_width > @width
      # compute thumb size and position
      thumb_width = (@width.to_f * (@width.to_f / total_width.to_f)).round
      thumb_width = [[thumb_width, 20].max, @width].min
      thumb_x = ((@scroll_x.to_f / max_offset.to_f) * (@width - thumb_width)).round

      # draw scrollbar thumb
      GTK.args.outputs[path].solids << [
        thumb_x,
        track_y,
        thumb_width,
        @scroll_bar_height,
        150, 150, 150, 255
      ]

      # store current thumb for click detection
      @current_thumb_rect = [@x + thumb_x, @y + track_y, thumb_width, @scroll_bar_height]
    else
      @current_thumb_rect = nil
    end

    # 3) composite the RT back into main outputs
    {
      x: @x,
      y: @y,
      w: @width,
      h: @height + @scroll_bar_height + 4,
      path: path,
      primitive_marker: :sprite
    }
  end

  private

  def handle_keys(inputs)
    total_width = @items.size * @item_width
    max_offset = [0, total_width - @width].max
    scroll_speed = 10
    delta = 0

    if inputs.keyboard.key_held.a
      delta -= 1
      # @scroll_x = [@scroll_x - scroll_speed, 0].max
    elsif inputs.keyboard.key_held.d
      delta += 1
      # @scroll_x = [@scroll_x + scroll_speed, max_offset].min
    end

    if delta != 0
      @scroll_vel += delta * 2.5
    end

    if @scroll_vel != 0
      @scroll_x += @scroll_vel
      @scroll_x = @scroll_x.clamp(0, max_offset)
    end

    @scroll_vel *= 0.9
  end

  def handle_scroll_bar(inputs)
    return if @current_thumb_rect.nil?

    mouse = inputs.mouse
    track_y = @y + 2
    total_width = @items.size * @item_width
    max_offset = [0, total_width - @width].max
    thumb_width = (@width.to_f * (@width.to_f / total_width.to_f)).round
    thumb_width = [[thumb_width, 20].max, @width].min

    # translate thumb rect into global coordinates
    thumb_x_global = @x + ((@scroll_x.to_f / max_offset.to_f) * (@width - thumb_width)).round
    thumb_rect = [thumb_x_global, track_y, thumb_width, @scroll_bar_height]

    if mouse.click && point_in_rect?(mouse.click, thumb_rect)
      @scroll_vel = 0
      @scroll_bar_dragging = true
      @scroll_bar_drag_start_mouse_x = mouse.click.x
      @scroll_bar_thumb_x_at_drag_start = thumb_x_global
    end

    if @scroll_bar_dragging && mouse.button_left
      dx = mouse.x - @scroll_bar_drag_start_mouse_x
      new_thumb_x = (@scroll_bar_thumb_x_at_drag_start + dx).clamp(@x, @x + @width - thumb_width)
      rel = (new_thumb_x - @x).to_f / (@width - thumb_width).to_f
      @scroll_x = (rel * max_offset).round
    end

    @scroll_bar_dragging = false if @scroll_bar_dragging && !mouse.button_left
  end

  def detect_click(inputs)
    @hovered_idx = nil
    @items.each_with_index do |item, idx|
      item_x = @x + (idx * @item_width) - @scroll_x
      item_y = @y + @scroll_bar_height + 4

      # skip if outside widget vertically or horizontally
      next if item_x + @item_width < @x
      next if item_x > @x + @width

      # check hover
      if inputs.mouse.point.inside_rect?([item_x, item_y, @item_width, @item_height])
        @hovered_idx = idx
        # on a click (mouse press), select the item
        if inputs.mouse.click
          @selected_item = item
          break
        end
      end
    end
  end

  def point_in_rect?(point, rect)
    px, py = point.x, point.y
    rx, ry, rw, rh = rect
    px >= rx && px <= rx + rw && py >= ry && py <= ry + rh
  end
end