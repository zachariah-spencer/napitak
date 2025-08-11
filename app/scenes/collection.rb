class Collection < Scene
  def initialize(title:, collection_array: [])
    @sc_id = "collection"
    @title = title
    @recipe_cards = []
    @page = 1
    @total_pages = ($recipe_book.unlocked_recipes.size / 8).ceil
    @total_pages = 1 if @total_pages <= 0

    max_col = 4
    max_row = 4
    col = 1
    row = 1
    page = 1
    spacing = 50
    start_x = -75

    collection_array.each do |card_id|
      @recipe_cards << RecipeCard.new(
        page: page,
        x: start_x + ((200 + spacing) * col),
        y: (GTK.args.grid.h - 90) - ((285 - spacing) * row),
        w: 185,
        h: 185,
        id: card_id
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
    @recipe_cards.each { |card| card.tick }
    calc
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
        size_px: 40,
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
        primitive_marker: :label
      }

      l3 << [back_btn]
      l3 << [prev_pg_btn, next_pg_btn, page_count_label] if @total_pages != 1
      l3
    when 4
      l4 << []
      l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

  def prev_pg_btn
    GTK.args.outputs[:prev_pg_btn].w = 150
    GTK.args.outputs[:prev_pg_btn].h = 75

    GTK.args.outputs[:prev_pg_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:prev_pg_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 70,
      g: 70,
      b: 150,
      a: 100,
      primitive_marker: :solid
    }

    GTK.args.outputs[:prev_pg_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: "<<",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w / 2 - 150 - 100,
      y: 50,
      w: 150,
      h: 75,
      angle: 0,
      path: :prev_pg_btn,
      primitive_marker: :sprite
    }
  end

  def next_pg_btn
    GTK.args.outputs[:next_pg_btn].w = 150
    GTK.args.outputs[:next_pg_btn].h = 75

    GTK.args.outputs[:next_pg_btn].primitives << {
      x: 0,
      y: 0,
      w: 150,
      h: 75,
      angle: 0,
      r: 0,
      g: 0,
      b: 0,
      primitive_marker: :solid
    }

    GTK.args.outputs[:next_pg_btn].primitives << {
      x: 5,
      y: 5,
      w: 140,
      h: 65,
      angle: 0,
      r: 70,
      g: 70,
      b: 150,
      a: 100,
      primitive_marker: :solid
    }

    GTK.args.outputs[:next_pg_btn].primitives << {
      x: 150 / 2,
      y: 75 / 2,
      text: ">>",
      anchor_x: 0.5,
      anchor_y: 0.5,
      r: 255,
      g: 255,
      b: 255,
      size_enum: 3
    }

    {
      x: GTK.args.grid.w / 2 + 0 + 100,
      y: 50,
      w: 150,
      h: 75,
      angle: 0,
      path: :next_pg_btn,
      primitive_marker: :sprite
    }
  end

  def back_btn
    f_i = 0.frame_index(count: 4, hold_for: 15, repeat: true)
    {
      x: 48,
      y: GTK.args.grid.h - 16 - 32,
      w: 32,
      h: 32,
      path: "sprites/back_button-sheet-4.png",
      tile_x: 32 * f_i,
      tile_y: 0,
      tile_w: 32,
      tile_h: 32,
      angle: 0
    }
  end

  def calc
    if GTK.args.inputs.mouse.click and
         Geometry.intersect_rect?(GTK.args.inputs.mouse, back_btn)
      cleanup
      $game.toggle_collection
    end

    @page += 1 if (
      GTK.args.inputs.mouse.click and
        Geometry.intersect_rect?(GTK.args.inputs.mouse, next_pg_btn) and
        @page < @total_pages
    )
    @page -= 1 if (
      GTK.args.inputs.mouse.click and
        Geometry.intersect_rect?(GTK.args.inputs.mouse, prev_pg_btn) and
        @page > 1
    )
  end

  def cleanup
  end
end
