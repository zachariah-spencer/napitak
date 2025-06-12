class Journal
  attr_gtk
  attr :sc_id

  def initialize(pause_menu_instance:)
    @sc_id               = "journal"
    @pause_menu_instance = pause_menu_instance

    @recipe_ids         = $recipe_book.unlocked_recipes
    @recipe_cards       = []
    @scroll_offset      = 0
    @scrollbar_dragging = false

    # layout constants
    @card_w            = 185
    @card_h            = 185
    @spacing_x         = 50
    @spacing_y         = 50
    @max_cols          = 4
    @max_visible_rows  = 2
    @scrollbar_width   = 8
    @scrollbar_margin  = 20

    build_cards
  end

  # populate @recipe_cards and compute total rows
  def build_cards
    @recipe_cards.clear
    col = 0
    row = 0
    start_x = -75
    start_y = GTK.args.grid.h - 90

    @recipe_ids.each do |recipe_id|
      x = start_x + col * (@card_w + @spacing_x)
      y = start_y - row * (@card_h + @spacing_y)
      @recipe_cards << RecipeCard.new(x: x, y: y, w: @card_w, h: @card_h, id: recipe_id)

      col += 1
      if col >= @max_cols
        col = 0
        row += 1
      end
    end

    @total_rows = row + 1
  end

  def tick
    handle_scroll
    @recipe_cards.each(&:tick)
    calc
  end

  # handles wheel scrolling & thumb dragging
  def handle_scroll
    return if @total_rows <= @max_visible_rows

    # 1) wheel scroll
    wheel = GTK.args.inputs.mouse.wheel.to_f
    if wheel.abs > 0
      @scroll_offset = (@scroll_offset + wheel * 20).clamp(-max_scroll, 0)
    end

    # compute track geometry
    @track_h = @max_visible_rows * (@card_h + @spacing_y) - @spacing_y
    @track_x = GTK.args.grid.w - @scrollbar_margin - @scrollbar_width
    @track_y = GTK.args.grid.h / 2

    # thumb size & pos
    @thumb_h = (@max_visible_rows.to_f / @total_rows * @track_h).to_i
    @thumb_h = [@thumb_h, @track_h].min
    track_top = @track_y + @track_h/2
    track_bottom = @track_y - @track_h/2

    scroll_ratio = -@scroll_offset / max_scroll.to_f
    @thumb_y = track_top - scroll_ratio * (@track_h - @thumb_h) - @thumb_h/2

    mouse = GTK.args.inputs.mouse
    over_thumb = Geometry.intersect_rect?(
      { x: mouse.x, y: mouse.y, w: 1, h: 1 },
      scrollbar_thumb_rect
    )

    # start dragging?
    if mouse.button_left && over_thumb
      @scrollbar_dragging = true
      @drag_start_y = mouse.y
      @thumb_start_y = @thumb_y
    elsif !mouse.button_left
      @scrollbar_dragging = false
    end

    # update scroll via drag
    if @scrollbar_dragging
      dy = mouse.y - @drag_start_y
      new_thumb_y = (@thumb_start_y + dy).clamp(
        track_bottom + @thumb_h/2,
        track_top - @thumb_h/2
      )
      @thumb_y = new_thumb_y

      # convert thumb pos back into scroll_offset
      scroll_ratio = (track_top - @thumb_h/2 - @thumb_y) / (@track_h - @thumb_h)
      @scroll_offset = (-max_scroll * scroll_ratio).to_i
    end
  end

  # max pixels we can scroll
  def max_scroll
    total_h = @total_rows * (@card_h + @spacing_y) - @spacing_y
    visible_h = @max_visible_rows * (@card_h + @spacing_y) - @spacing_y
    [0, total_h - visible_h].max
  end

  # helper rects for hit tests
  def scrollbar_track_rect
    { x: @track_x, y: @track_y, w: @scrollbar_width, h: @track_h }
  end

  def scrollbar_thumb_rect
    { x: @track_x, y: @thumb_y, w: @scrollbar_width, h: @thumb_h }
  end

  # primitive hashes
  def scrollbar_track
    scrollbar_track_rect.merge(
      r: 100, g: 100, b: 100, a: 150,
      primitive_marker: :solid
    )
  end

  def scrollbar_thumb
    scrollbar_thumb_rect.merge(
      r: 200, g: 200, b: 200, a: 200,
      primitive_marker: :solid
    )
  end

  def render(layer_num)
    case layer_num
    when 0
      background = {
        x: 0, y: 0, w: GTK.args.grid.w, h: GTK.args.grid.h,
        r: 10, g: 10, b: 20, primitive_marker: :solid
      }
      [ [ background ] ]

    when 1
      []  # (panels omitted for brevity)

    when 2
      encounter_label = {
        x: GTK.args.grid.w/2, y: GTK.args.grid.h-50,
        alignment_enum: 1,
        size_px: (Math.sin(Kernel.tick_count*0.08)*4 + 40).to_i,
        r:255, g:255, b:255, text:"Journal", primitive_marker: :label
      }
      [ [ encounter_label ] ]

    when 3
      layer = [ back_btn ]
      if @total_rows > @max_visible_rows
        layer << scrollbar_track
        layer << scrollbar_thumb
      end
      [ layer ]

    when 4
      visible_top    = GTK.args.grid.h - 90
      visible_bottom = visible_top - (@max_visible_rows * (@card_h + @spacing_y)) + @spacing_y

      non_hover = []
      hover     = []

      @recipe_cards.each do |card|
        prefab = card.prefab.dup
        prefab[0][:y] += @scroll_offset

        next if prefab[0][:y] > visible_top || prefab[0][:y] < visible_bottom

        if card.hovered
          hover << prefab
        else
          non_hover << prefab
        end
      end

      [ non_hover, hover ]
    end
  end

  def back_btn
    {
      x: 20, y: GTK.args.grid.h-60, w:40, h:40,
      path: "sprites/circle/red.png", angle: 0
    }
  end

  def calc
    m = GTK.args.inputs.mouse
    if m.click && Geometry.intersect_rect?(m, back_btn)
      cleanup
      @pause_menu_instance.go_back
    end
  end

  def cleanup; end
end
