class Collection < Scene
  def initialize(title:, collection_array: [])
    @sc_id = "collection"
    @title = title
    @recipe_cards = []
    @page = 1
    @total_pages = (collection_array.size / 8).ceil
    @total_pages = 1 if @total_pages <= 0

    max_col = 4
    max_row = 4
    col = 1
    row = 1
    page = 1
    spacing = 50
    start_x = -75
    @next_pg_btn = Button.new(x: GTK.args.grid.w / 2 - 32 + 128, y: 64 + 16, w: 64, h: 64, text: ">", text_size_px: 64, path: "sprites/button_frame-128x128-sheet-4.png",
    tile_rect: { x: 128, y: 0, w: 128, h: 128 },
    frame_length: 4, anchor_y: 0.43, active: false)
    @prev_pg_btn = Button.new(x: GTK.args.grid.w / 2 - 96, y: 64 + 16, w: 64, h: 64, text: "<", text_size_px: 64, path: "sprites/button_frame-128x128-sheet-4.png",
    tile_rect: { x: 128, y: 0, w: 128, h: 128 },
    frame_length: 4, anchor_y: 0.43, active: false)
    @back_btn = Button.new(
      x: 64,
      y: GTK.args.grid.h - 16 - 16,
      w: 32,
      h: 32,
      path: "sprites/back_button-sheet-4.png",
      text: "",
      frame_length: 4,
      tile_rect: {
        x: 32,
        y: 0,
        w: 32,
        h: 32,
      }
    )

    @buttons = [@prev_pg_btn, @next_pg_btn, @back_btn]

    collection_array.each do |card|
      w = 185
      h = 185
      @recipe_cards << CollectionCard.new(
        page: page,
        # adjust to center-based card position (anchor 0.5)
        x: start_x + ((200 + spacing) * col) + (w / 2),
        y: (GTK.args.grid.h - 90) - ((285 - spacing) * row) + (h / 2),
        w: w,
        h: h,
        id: card.id,
        uses_left: card.uses_left
      )
      if col % max_col == 0
        if row == 2
          row = 1
          page += 1
        else
          row += 1
        end
        col = 0
      end
      col += 1
    end
  end

  def tick
    @buttons.each { |b| b.tick }

    card_viewed = @recipe_cards.any? { |c| c.viewed }
    @recipe_cards.each do |card| 
      card.tick
      card.faded = (card_viewed && !card.viewed)
    end
    calc
  end
  
  def card_viewed?
    @recipe_cards.find { |c| c.viewed }
  end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    @recipe_cards.each do |card|
      next unless @page == card.page
      card.hovered ? l4 << card.prefab : l3 << card.prefab
    end

    bg_tile_index = 0.frame_index(24, 1.0.seconds, true)

    case layer_num
    when 0
      background_solid = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 0,
        g: 0,
        b: 0,
        primitive_marker: :solid
      }
      background = {
        x: 0,
        y: 0,
        w: 1280,
        h: 720,
        r: 50,
        g: 50,
        b: 50,
        a: 200,
        path:
          "sprites/background_frames/sketchybackground#{bg_tile_index + 1}.png"
      }

      l0 << [background_solid, background]

      l0
    when 1
      left_panel ||= {
        x: 0,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid
      }

      right_panel ||= {
        x: GTK.args.grid.w - 200,
        y: 0,
        w: 200,
        h: GTK.args.grid.h,
        r: 50,
        g: 50,
        b: 50,
        a: 50,
        primitive_marker: :solid
      }

      # l1 << [left_panel, right_panel]
      l1
    when 2
      encounter_label ||= {
        x: GTK.args.grid.w / 2,
        y: GTK.args.grid.h - 50,
        alignment_enum: 1,
        size_px: 55,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@title}",
        font: $FONT,
        primitive_marker: :label
      }
      l2 << [encounter_label]
      l2
    when 3
      page_count_label ||= {
        x: GTK.args.grid.w / 2,
        y: 100,
        alignment_enum: 1,
        size_enum: 5,
        r: 255,
        g: 255,
        b: 255,
        text: "#{@page} / #{@total_pages}",
        font: $FONT,
        primitive_marker: :label
      }

      l3 << [@back_btn.prefab]
      l3 << [@prev_pg_btn.prefab, @next_pg_btn.prefab, page_count_label] if @total_pages != 1
      l3
    when 4
      l4 << []
      l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def calc
    if @back_btn.clicked?
      $game.toggle_collection
    end

    @next_pg_btn.set_active((@page < @total_pages) && !card_viewed?)
    @prev_pg_btn.set_active((@page > 1) && !card_viewed?)

    if (@next_pg_btn.clicked? && @page < @total_pages)
      @page += 1 
      $AUDIO_SERVICE.play_sound(:page_turn)
    end
    if (@prev_pg_btn.clicked? && @page > 1)
      @page -= 1
      $AUDIO_SERVICE.play_sound(:page_reverse_turn)
    end
  end

end
