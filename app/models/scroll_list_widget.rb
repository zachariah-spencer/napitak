class ScrollListWidget
    attr_reader :selected_item

    def initialize(items:, x:, y:, w:, h:, item_height: 64, uid:)
        @items         = items
        @x, @y         = x, y
        @width         = w
        @height        = h
        @item_height   = item_height
        @scroll_y      = 0
        @scroll_vel    = 0
        @hovered_idx   = nil
        @selected_item = nil
        @uid = uid
    end

    def rect()
        [
            @x,
            @y,
            @width,
            @height,
        ]
    end

    def add_item(item)
        @items.unshift(item)
        item
    end

    def remove_item(item)
        @items.delete(item)
        item
    end


    # update scroll, clear last click, then detect a new one
    def tick(inputs)
        handle_scroll(inputs)
        @selected_item = nil              # ← reset every frame
        detect_click(inputs)
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
=begin
    # Returns an array of DragonRuby "prefabs" (solids & labels)
    def render
        prefabs = []

        # background
        prefabs << [x: @x, y: @y, w: @width, h: @height, r: 0, g: 0, b: 0, a: 160, primitive_marker: :solid]

        @items.each_with_index do |item, idx|
            item_x = @x
            item_y = @y + @height + @scroll_y - (idx + 1) * @item_height
            next unless visible?(item_y)

            # choose highlight color if hovered
            color = (@hovered_idx == idx) ? [80, 80, 80] : [100, 100, 100]
            prefabs << [x: item_x, y: item_y, w: @width, h: @item_height, r: color[0], g: color[1], b: color[2], primitive_marker: :solid]
            prefabs << {
                x: item_x + 32, 
                y: item_y + (@item_height / 2) - 8,
                w: 32, 
                h: 32, 
                path: item.img,
                primitive_marker: :sprite,
            }

            # label prefab
            prefabs << {
                x:         item_x + 8,
                y:         item_y + (@item_height / 2) - 8,
                text:      item.name,
                size_enum: 1,
                primitive_marker: :label,
            }
        end

        prefabs
    end
=end

    # draws into the RT and composites it back
    def render()
        path = "sl_widget_rt_" + @uid.to_s()

        # 1) (Re)initialize the RT buffer at the widget's size
        GTK.args.outputs[path].w = @width
        GTK.args.outputs[path].h = @height
        # background
        GTK.args.outputs[path].solids << [0, 0, @width, @height, 0, 0, 0, 160]

        @items.each_with_index do |item, idx|
            local_x = 0
            local_y = @height - ((idx + 1) * @item_height) - @scroll_y
            # skip fully off‐screen rows
            next if local_y + @item_height < 0
            next if local_y > @height

            # slot
            color = (@hovered_idx == idx) ? [80, 80, 80] : [100, 100, 100]
            GTK.args.outputs[path].solids << [local_x + 5, local_y + 5, @width - 10, @item_height - 10, *color]

            # icon
            GTK.args.outputs[path].sprites << {
                x:    local_x + 32,
                y:    local_y + (@item_height / 2) - 8,
                w:    32,
                h:    32,
                path: item.img
            }

            # label
            GTK.args.outputs[path].labels << {
                x:         local_x + 8,
                y:         local_y + (@item_height / 2) - 8,
                text:      item.name,
                size_enum: 1
            }

            if item.id[0] == "p"
                # uses left label for potions
                GTK.args.outputs[path].labels << {
                    x:         local_x + 96,
                    y:         local_y + (@item_height / 2) + 20,
                    text: "#{item.uses_left} / #{item.max_uses}",
                    size_enum: 1
                }
            end
        end

        # 3) composite the RT back into main outputs
        {
            x:    @x,
            y:    @y,
            w:    @width,
            h:    @height,
            path: path,
            primitive_marker: :sprite,
        }
    end

    private

    def handle_scroll(inputs)
        max_offset = [0, (@items.size * @item_height) - @height].max

        if inputs.mouse.intersect_rect?([@x, @y, @width, @height])
        
            wheel = inputs.mouse.wheel || { x: 0, y: 0 }
            delta = wheel[:y] 

            if delta != 0
                @scroll_vel += delta * 1.75
                # @scroll_y = (@scroll_y - delta * 10).clamp(0, max_offset)
            end

            if @scroll_vel != 0 
                @scroll_y += (@scroll_vel)
                @scroll_y = @scroll_y.clamp(-max_offset, 0)
            end

            @scroll_vel *= 0.90
        end
    end


    # def detect_click(inputs)
    #     @hovered_idx = nil
    #     @items.each_with_index do |item, idx|
    #         item_x = @x
    #         item_y = @y + @height - @scroll_y - (idx + 1) * @item_height
    #         next if item_y + @item_height < @y
    #         next if item_y > @y + @height
# 
    #         if inputs.mouse.point.inside_rect?([item_x, item_y, @width, @item_height])
    #             @hovered_idx = idx
    #             @selected_item = item if inputs.mouse.click
    #         end
    #     end
    # end

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
                @selected_item = item   # ← only set on an actual click
                break                   # ← stop after first hit
                end
            end
        end
    end
end
