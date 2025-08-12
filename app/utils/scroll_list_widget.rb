class ScrollListWidget
  attr_reader :selected_item

  def initialize(items:, x:, y:, w:, h:, item_height: 96)
    @items = items
    @x, @y = x, y
    @width = w
    @height = h
    @item_height = item_height
    @scroll_y = 0
    @scroll_vel = 0
    @hovered_idx = nil
    @selected_item = nil
    @uid = GameUtils.new_id?
    @frame_index_start_ticks = {}

    @items.each { |item| @frame_index_start_ticks[item.entity_id] = Numeric.rand(0..120) }
  end

  def rect
    [@x, @y, @width, @height]
  end

  def add_item(item)
    @items.unshift(item)
    @frame_index_start_ticks[item.entity_id] = Numeric.rand(0..120)
    item
  end

  def clear_items
    @items.clear
  end

  def remove_item(item)
    @items.delete(item)
    @frame_indexes.delete(item.entity_id)
    item
  end

  def items?
    return @items
  end

  # update scroll, clear last click, then detect a new one
  def tick(inputs)
    if !$game.input_locked
      handle_scroll(inputs)
      @selected_item = nil # ← reset every frame
      detect_click(inputs)
    else
      @hovered_idx = nil
    end
  end

  # after render/tick, caller can do widget.pop_clicked
  def pop_clicked
    item = @selected_item
    @selected_item = nil
    item
  end

  def visible?(item_y)
    item_y < @y + @height && (item_y + @item_height) > @y
  end

  # draws into the RT and composites it back
  def render
    path = "sl_widget_rt_" + @uid.to_s()

    # 1) (Re)initialize the RT buffer at the widget's size
    GTK.args.outputs[path].w = @width
    GTK.args.outputs[path].h = @height
    # background
    # GTK.args.outputs[path].solids << [0, 0, @width, @height, 0, 0, 0, 160]

    @items.each_with_index do |item, idx|
      f_i = (Numeric.frame_index(start_at: @frame_index_start_ticks[item.entity_id],
                              count: 4,
                              hold_for: 0.5.seconds,
                              repeat: true))

      puts f_i

      local_x = 0
      local_y = @height - ((idx + 1) * @item_height) - @scroll_y
      # skip fully off‐screen rows
      next if local_y + @item_height < 0
      next if local_y > @height

      # slot
      color = (@hovered_idx == idx) ? [255, 255, 255, 255] : [255, 255, 255, 255]
      GTK.args.outputs[path].sprites << {
        x: local_x + 5,
        y: local_y + 5,
        w: @width - 10,
        h: @item_height - 10,
        r: color[0],
        g: color[1],
        b: color[2],
        a: color[3],
        path: "sprites/button_frame-128x128-sheet-4.png",
        tile_x: 128 * f_i,
        tile_y: 0,
        tile_w: 128,
        tile_h: 128
      }

      # label

      if GameUtils.is_potion(item.id)
        GTK.args.outputs[path].labels << {
          x: local_x + @width / 2,
          y: local_y + (@item_height / 2) + 34,
          text: item.name,
          size_px: 12,
          r: 255,
          g: 255,
          b: 255,
          font: $FONT,
          alignment_enum: 1
        }
        # uses left label for potions
        GTK.args.outputs[path].labels << {
          x: local_x + @width / 2,
          y: local_y + (@item_height / 2) - 22,
          text: "#{item.uses_left}/#{item.max_uses}",
          alignment_enum: 1,
          r: 255,
          g: 255,
          b: 255,
          size_px: 16,
          font: $FONT
        }

        # icon for potions
        GTK.args.outputs[path].sprites << {
          x: local_x + @width / 2 - 16,
          y: local_y + (@item_height / 2) - 16,
          w: 32,
          h: 32,
          path: item.img
        }
      else
        GTK.args.outputs[path].labels << {
          x: local_x + @width / 2,
          y: local_y + (@item_height / 2) - 15,
          text: item.name,
          size_px: 12,
          font: $FONT,
          r: 255,
          g: 255,
          b: 255,
          alignment_enum: 1
        }
        # icon
        GTK.args.outputs[path].sprites << {
          x: local_x + @width / 2 - 16,
          y: local_y + (@item_height / 2) - 8,
          w: 32,
          h: 32,
          path: item.img
        }
      end
    end

    # 3) composite the RT back into main outputs
    {
      x: @x,
      y: @y,
      w: @width,
      h: @height,
      path: path,
      primitive_marker: :sprite
    }
  end

  private

  def handle_scroll(inputs)
    max_offset = [0, (@items.size * @item_height) - @height].max

    if inputs.mouse.intersect_rect?([@x, @y, @width, @height])
      wheel = inputs.mouse.wheel || { x: 0, y: 0 }
      delta = wheel[:y]

      if delta != 0
        @scroll_vel += delta * 2.5
        # @scroll_y = (@scroll_y - delta * 10).clamp(0, max_offset)
      end

      if @scroll_vel != 0
        @scroll_y += (@scroll_vel)
        @scroll_y = @scroll_y.clamp(-max_offset, 0)
      end

      @scroll_vel *= 0.90
    end
  end

  def detect_click(inputs)
    @hovered_idx = nil
    @items.each_with_index do |item, idx|
      # compute world-space item_y just like in render
      item_y = @y + @height - ((idx + 1) * @item_height) - @scroll_y

      next if item_y + @item_height < @y
      next if item_y > @y + @height

      if inputs.mouse.point.inside_rect?([@x, item_y, @width, @item_height])
        @hovered_idx = idx
        if inputs.mouse.click
          @selected_item = item # ← only set on an actual click
          break # ← stop after first hit
        end
      end
    end
  end
end
